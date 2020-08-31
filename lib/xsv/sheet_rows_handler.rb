# frozen_string_literal: true
module Xsv
  # This is the core worksheet parser, implemented as an Ox::Sax handler. This is
  # used internally to enumerate rows.
  class SheetRowsHandler < SaxParser
    include Xsv::Helpers

    def format_cell
      return nil if @current_value.empty?

      case @current_cell[:t]
      when "s"
        @workbook.shared_strings[@current_value.to_i]
      when "str", "inlineStr"
        @current_value.dup
      when "e" # N/A
        nil
      when nil, "n"
        if @current_cell[:s]
          style = @workbook.xfs[@current_cell[:s].to_i]
          numFmt = @workbook.numFmts[style[:numFmtId].to_i]

          parse_number_format(@current_value, numFmt)
        else
          parse_number(@current_value)
        end
      when "b"
        @current_value == "1"
      else
        raise Xsv::Error, "Encountered unknown column type #{@current_cell[:t]}"
      end
    end

    def initialize(mode, empty_row, workbook, row_skip, last_row, &block)
      @block = block

      # :sheetData
      # :row
      # :c
      # :v
      @state = nil

      @mode = mode
      @empty_row = empty_row
      @workbook = workbook
      @row_skip = row_skip
      @row_index = 0
      @current_row = {}
      @current_row_attrs = {}
      @current_cell = {}
      @current_value = String.new
      @last_row = last_row

      if @mode == :hash
        @headers = @empty_row.keys
      end
    end

    def start_element(name, attrs)
      case name
      when "c"
        @state = name
        @current_cell = attrs.map { |k, v| [k.to_sym, v] }.to_h
        @current_value.clear
      when "v", "is"
        @state = name
      when "row"
        @state = name
        @current_row = @empty_row.dup
        @current_row_attrs.clear
      when "t"
        @state = nil unless @state == :is
        @current_row_attrs = attrs.map { |k, v| [k.to_sym, v] }.to_h
      else
        @state = nil
      end
    end

    def characters(value)
      if @state == "v" || @state == "is"
        @current_value << value
      end
    end

    def end_element(name)
      case name
      when "v"
        @state = nil
      when "c"
        col_index = column_index(@current_cell[:r])

        case @mode
        when :array
          @current_row[col_index] = format_cell
        when :hash
          @current_row[@headers[col_index]] = format_cell
        end
      when "row"
        @real_row_number = @current_row_attrs[:r].to_i
        @adjusted_row_number = @real_row_number - @row_skip

        if @real_row_number <= @row_skip
          return
        end

        @row_index += 1

        # Skip first row if we're in hash mode
        return if @adjusted_row_number == 1 && @mode == :hash

        # Pad empty rows
        while @row_index < @adjusted_row_number
          @block.call(@empty_row)
          @row_index += 1
          next
        end

        # Do not return empty trailing rows
        @block.call(@current_row) unless @row_index > @last_row - @row_skip
      end
    end
  end
end
