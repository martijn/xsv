# frozen_string_literal: true

module Xsv
  # This is the core worksheet parser, implemented as an Ox::Sax handler. This is
  # used internally to enumerate rows.
  class SheetRowsHandler < SaxParser
    include Xsv::Helpers

    def initialize(mode, headers, empty_row, workbook, row_skip, last_row, &block)
      @mode = mode
      @headers = headers
      @empty_row = empty_row
      @workbook = workbook
      @row_skip = row_skip
      @last_row = last_row - @row_skip
      @block = block

      @store_characters = false

      @row_index = 0
      @col_index = 0
      @current_row = {}
      @current_row_number = 0
      @current_cell = {}
      @current_value = +""
    end

    def start_element(name, attrs)
      case name
      when "c"
        @current_cell = attrs
        @current_value.clear
      when "v", "is", "t"
        @store_characters = true
      when "row"
        @current_row = (@mode == :array) ? [] : @empty_row.dup
        @current_row_number = attrs[:r].to_i
      end
    end

    def characters(value)
      @current_value << value if @store_characters
    end

    def end_element(name)
      case name
      when "v", "is", "t"
        @store_characters = false
      when "c"
        col_index = @current_cell[:r] ? column_index(@current_cell[:r]) : @col_index

        if @mode == :array
          @current_row[col_index] = format_cell
        else
          @current_row[@headers[col_index]] = format_cell unless @headers[col_index].nil?
        end

        @col_index += 1
      when "row"
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
    end

    private

    def format_cell
      return nil if @current_value.empty?

      case @current_cell[:t]
      when "s"
        @workbook.shared_strings[@current_value.to_i]
      when "str", "inlineStr"
        -@current_value.strip
      when "e" # N/A
        nil
      when nil, "n"
        if @current_cell[:s]
          parse_number_format(@current_value, @workbook.get_num_fmt(@current_cell[:s].to_i))
        else
          parse_number(@current_value)
        end
      when "b"
        @current_value == "1"
      when "d"
        DateTime.parse(@current_value)
      else
        raise Xsv::Error, "Encountered unknown column type #{@current_cell[:t]}"
      end
    end
  end
end
