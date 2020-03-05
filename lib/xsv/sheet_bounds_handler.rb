# frozen_string_literal: true
module Xsv
  # SheetBoundsHandler scans a sheet looking for the outer bounds of the content within.
  # This is used internally when opening a sheet to deal with worksheets that do not
  # have a correct dimension tag.
  class SheetBoundsHandler < Ox::Sax
    include Xsv::Helpers

    def self.get_bounds(sheet, workbook)
      rows = 0
      cols = 0

      handler = new(workbook.trim_empty_rows) do |row, col|
        rows = row
        cols = col == 0 ? 0 : col + 1

        return rows, cols
      end

      sheet.rewind if sheet.respond_to?(:rewind)
      Ox.sax_parse(handler, sheet)

      return rows, cols
    end

    # Ox::Sax implementation

    def initialize(trim_empty_rows, &block)
      @block = block
      @state = nil
      @cell = nil
      @row = nil
      @maxRow = 0
      @maxColumn = 0
      @trim_empty_rows = trim_empty_rows
    end

    def start_element(name)
      case name
      when :c
        @state = name
        @cell = nil
      when :v
        col = column_index(@cell)
        @maxColumn = col if col > @maxColumn
        @maxRow = @row if @row > @maxRow
      when :row
        @state = name
        @row = nil
      when :dimension
        @state = name
      end
    end

    def end_element(name)
      if name == :sheetData
        @block.call(@maxRow, @maxColumn)
      end
    end

    def attr(name, value)
      if @state == :c && name == :r
        @cell = value
      elsif @state == :row && name == :r
        @row = value.to_i
      elsif @state == :dimension && name == :ref
        _firstCell, lastCell = value.split(":")

        if lastCell
          @maxColumn = column_index(lastCell)
          unless @trim_empty_rows
            @maxRow = lastCell[/\d+$/].to_i
            @block.call(@maxRow, @maxColumn)
          end
        end
      end
    end
  end
end
