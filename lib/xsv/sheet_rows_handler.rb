# frozen_string_literal: true

module Xsv
  # This is the core worksheet parser, used internally to enumerate rows.
  #
  # Because it is the hot path when reading a sheet, it does not use the callbacks of {SaxParser}.
  # It scans the worksheet XML itself and recognizes the few elements it needs (row, c, v, is
  # and t) by their bytes, so it doesn't allocate strings for element names, attributes or text
  # it doesn't use.
  class SheetRowsHandler < SaxParser
    include Xsv::Helpers

    # Byte values used to recognize element and attribute names
    SLASH = 47 # /
    LOWER_C = 99 # c
    LOWER_I = 105 # i
    LOWER_O = 111 # o
    LOWER_R = 114 # r
    LOWER_S = 115 # s
    LOWER_T = 116 # t
    LOWER_V = 118 # v
    LOWER_W = 119 # w
    SPACE = 32
    QUOTE = 34 # "
    COLON = 58
    LT = 60 # <
    EQUALS = 61 # =
    GT = 62 # >
    ZERO = 48
    NINE = 57

    # Cell types by their single byte name, or by their name
    SINGLE_BYTE_CELL_TYPES = {"s".ord => :s, "n".ord => :n, "b".ord => :b, "e".ord => :e, "d".ord => :d}.freeze
    CELL_TYPES = {"str" => :str, "inlineStr" => :inlineStr}.freeze

    def initialize(mode, headers, empty_row, workbook, row_skip, last_row, &block)
      @mode = mode
      @headers = headers
      @empty_row = empty_row
      @workbook = workbook
      @row_skip = row_skip
      @last_row = last_row - @row_skip
      @block = block

      @row_index = 0
      @col_index = 0
      @current_row = {}
      @current_row_number = 0
      @number_formats = {}
    end

    # standard:disable Style/InfiniteLoop
    def parse(io)
      if io.is_a?(String)
        buf = io.dup.force_encoding(Encoding::UTF_8)
        eof_reached = true
      else
        buf = String.new(capacity: CHUNK_SIZE * 2, encoding: Encoding::UTF_8)
        eof_reached = false
      end

      pos = 0 # start of the unparsed data in buf, right after a ">" unless it is 0
      waiting_for_row_end = false

      # Elements are parsed by #parse_next, which is called often enough to be compiled by YJIT
      # quickly, unlike this method.
      while true
        # Don't parse an incomplete row again until its end might be in the buffer
        unless waiting_for_row_end && !eof_reached && !buf.byteindex("row>", (pos > 0) ? pos - 1 : 0)
          if (next_pos = parse_next(buf, pos))
            pos = next_pos
            waiting_for_row_end = false
            next
          end

          waiting_for_row_end = true
        end

        if eof_reached
          last_lt = buf.byterindex("<")
          raise Xsv::Error, "Malformed XML document, looking for end of tag beyond EOF" if last_lt && !buf.byteindex(">", last_lt)
          # Discard anything after the last tag in the document
          break
        end

        # Drop the parsed data and append the next chunk
        buf = buf.byteslice(pos, buf.bytesize - pos) if pos > 0
        pos = 0

        if (chunk = read_chunk(io))
          buf << chunk
        else
          eof_reached = true
        end
      end
    end

    private

    # Parses the next element after pos, which is either a complete row or a single tag outside
    # of a row, and returns the position after it. Returns nil if it is not completely in buf yet,
    # without changing any state, so it can be parsed again after reading more data.
    def parse_next(buf, pos)
      # Search from the ">" before pos, as byteindex requires a character boundary
      return unless (lt = buf.byteindex("<", (pos > 0) ? pos - 1 : 0))
      return unless (gt = buf.byteindex(">", lt))
      return gt + 1 if buf.getbyte(lt + 1) == SLASH

      # Find the element name, without XML namespace
      name_end = lt + 1
      name_end += 1 while (byte = buf.getbyte(name_end)) != SPACE && byte != GT
      name_start = name_end
      name_start -= 1 while name_start > lt + 1 && buf.getbyte(name_start - 1) != COLON

      # An element without attributes that closes itself has a name ending in "/", so it is not
      # recognized. That is consistent with SaxParser.
      return gt + 1 unless name_end - name_start == 3 && buf.getbyte(name_start) == LOWER_R &&
        buf.getbyte(name_start + 1) == LOWER_O && buf.getbyte(name_start + 2) == LOWER_W

      number = row_number(buf, name_end, gt) || @current_row_number + 1

      if buf.getbyte(gt - 1) == SLASH
        # An empty row. SaxParser never reported its end, so it is only returned as padding if
        # there are rows after it.
        @current_row_number = number
        return gt + 1
      end

      parse_row(buf, gt, number)
    end

    # Returns the r attribute of a row start tag as an Integer, reading attributes from offset up to gt
    def row_number(buf, offset, gt)
      while offset < gt
        offset += 1 while (byte = buf.getbyte(offset)) <= SPACE
        return if byte == GT || byte == SLASH

        key_start = offset
        while (byte = buf.getbyte(offset)) != EQUALS
          return if byte == GT
          key_start = offset + 1 if byte == COLON
          offset += 1
        end
        return unless buf.getbyte(offset + 1) == QUOTE

        return integer_at(buf, offset + 2) if offset - key_start == 1 && buf.getbyte(key_start) == LOWER_R

        offset += 2
        offset += 1 while (byte = buf.getbyte(offset)) != QUOTE && byte
        offset += 1
      end
    end

    # Parses the row whose start tag ends at row_gt, and returns the position after its end tag.
    # Returns nil if the end of the row is not in buf yet, without changing any state, so the row
    # can be parsed again after reading more data.
    #
    # The elements in a row are usually written the same way, so the common cases are recognized by
    # reading bytes at fixed offsets. That avoids most searches, which is especially fast with YJIT.
    # Anything else, like XML namespaces or other whitespace, is handled by the generic code paths.
    def parse_row(buf, row_gt, number)
      row = (@mode == :array) ? [] : @empty_row.dup
      col_index = @col_index

      store_characters = false
      value = nil # value of the current cell, nil if it has no text
      cell_column = nil
      cell_type = nil
      cell_style = nil

      # Cached positions of the next space, '="' and ':', see SaxParser#parse
      space = equals = colon = -1

      gt = row_gt
      while true
        # Find the next tag, which usually follows the previous one directly
        pos = gt + 1
        if buf.getbyte(pos) == LT
          lt = pos
        else
          return unless (lt = buf.byteindex("<", gt))

          if store_characters
            chars = buf.byteslice(pos, lt - pos)
            chars = CGI.unescapeHTML(chars) if chars.include?("&")
            value = value ? value + chars : chars
          end
        end

        first = buf.getbyte(lt + 1)

        if first == SLASH
          if buf.getbyte(lt + 3) == GT
            # Fast path for </c>, </v> and </t>
            gt = lt + 3
            name_start = lt + 2
          else
            return unless (gt = buf.byteindex(">", lt))
            colon = buf.byteindex(":", lt) || buf.bytesize if colon < lt
            name_start = (colon < gt) ? colon + 1 : lt + 2
          end

          name_length = gt - name_start
          first = buf.getbyte(name_start)

          if name_length == 1
            if first == LOWER_C
              column = cell_column || col_index

              if @mode == :array
                row[column] = format_cell(value, cell_type, cell_style)
              else
                header = @headers[column]
                row[header] = format_cell(value, cell_type, cell_style) unless header.nil?
              end

              col_index += 1
            elsif first == LOWER_V || first == LOWER_T
              store_characters = false
            end
          elsif name_length == 2
            store_characters = false if first == LOWER_I && buf.getbyte(name_start + 1) == LOWER_S
          elsif name_length == 3 && first == LOWER_R && buf.getbyte(name_start + 1) == LOWER_O && buf.getbyte(name_start + 2) == LOWER_W
            @current_row_number = number
            @current_row = row
            @col_index = col_index
            end_row

            return gt + 1
          end

          next
        end

        second = buf.getbyte(lt + 2)
        if second == GT
          # Fast path for <v>, <t> and other single character names without attributes
          gt = lt + 2
          name_length = 1
          attr_start = gt
        elsif second == SPACE && first == LOWER_C
          # Fast path for <c ...>
          return unless (gt = buf.byteindex(">", lt))
          name_length = 1
          attr_start = lt + 2
        else
          return unless (gt = buf.byteindex(">", lt))
          space = buf.byteindex(" ", lt) || buf.bytesize if space < lt
          colon = buf.byteindex(":", lt) || buf.bytesize if colon < lt

          # An element without attributes that closes itself has a name ending in "/", so it is
          # not recognized. That is consistent with SaxParser.
          attr_start = (space < gt) ? space : gt
          name_start = (colon < attr_start) ? colon + 1 : lt + 1
          name_length = attr_start - name_start
          first = buf.getbyte(name_start)
          second = buf.getbyte(name_start + 1)
        end

        if name_length == 1
          if first == LOWER_C
            # Read the attributes we need: r, t and s. A cell that closes itself has no value, and
            # SaxParser never reported its end, so its attributes are reset by the next cell.
            value = nil
            cell_column = cell_type = cell_style = nil

            # attr_start is the whitespace before an attribute
            while attr_start < gt
              if buf.getbyte(attr_start + 2) == EQUALS && buf.getbyte(attr_start + 3) == QUOTE
                # Fast path for a single character name after a single space
                key = buf.getbyte(attr_start + 1)
                value_start = attr_start + 4
              else
                equals = buf.byteindex('="', attr_start) || buf.bytesize if equals < attr_start
                break if equals > gt

                before = buf.getbyte(equals - 2)
                key = (before <= SPACE || before == COLON) ? buf.getbyte(equals - 1) : nil
                value_start = equals + 2
              end

              quote = begin
                buf.byteindex('"', value_start)
              rescue IndexError
                # The value starts with an invalid UTF-8 byte
                buf.b.byteindex('"', value_start)
              end
              break if quote.nil? || quote > gt

              if key == LOWER_R
                column = 0
                while (byte = buf.getbyte(value_start)) >= A_CODEPOINT
                  column = column * 26 + byte - A_CODEPOINT + 1
                  value_start += 1
                end
                cell_column = column - 1
              elsif key == LOWER_T
                cell_type = if quote - value_start == 1
                  SINGLE_BYTE_CELL_TYPES[buf.getbyte(value_start)]
                end
                if cell_type.nil?
                  name = buf.byteslice(value_start, quote - value_start)
                  cell_type = CELL_TYPES[name] || name
                end
              elsif key == LOWER_S
                cell_style = integer_at(buf, value_start)
              end

              attr_start = quote + 1
            end
          elsif first == LOWER_V || first == LOWER_T
            store_characters = true
          end
        elsif name_length == 2
          store_characters = true if first == LOWER_I && second == LOWER_S
        end
      end
    end
    # standard:enable Style/InfiniteLoop

    # Parses the unsigned integer starting at offset
    def integer_at(buf, offset)
      number = 0
      while (byte = buf.getbyte(offset)) && byte >= ZERO && byte <= NINE
        number = number * 10 + byte - ZERO
        offset += 1
      end
      number
    end

    def end_row
      return if @current_row_number <= @row_skip

      adjusted_row_number = @current_row_number - @row_skip

      @row_index += 1
      @col_index = 0

      # Skip first row if we're in hash mode
      return if adjusted_row_number == 1 && @mode == :hash

      # Pad empty rows
      while @row_index < adjusted_row_number
        @block.call(@empty_row)
        @row_index += 1
        next
      end

      # Do not return empty trailing rows
      return if @row_index > @last_row

      # Add trailing empty columns
      if @mode == :array && @current_row.length < @empty_row.length
        @block.call(@current_row + @empty_row[@current_row.length..])
      else
        @block.call(@current_row)
      end
    end

    def format_cell(value, type, style)
      return nil if value.nil? || value.empty?

      case type
      when :s
        @workbook.shared_strings[value.to_i]
      when :str, :inlineStr
        value.strip!
        -value
      when :e # N/A
        nil
      when nil, :n
        if style
          format_number(value, style)
        else
          parse_number(value)
        end
      when :b
        value == "1"
      when :d
        DateTime.parse(value)
      else
        raise Xsv::Error, "Encountered unknown column type #{type}"
      end
    end

    # Same as Helpers#parse_number_format, but determines the kind of number format once per style
    def format_number(value, style)
      number = parse_number(value)

      case @number_formats.fetch(style) { @number_formats[style] = number_format_kind(@workbook.get_num_fmt(style)) }
      when :date
        parse_date(number)
      when :time
        parse_time(number)
      when :datetime
        parse_datetime(number)
      else
        number
      end
    end
  end
end
