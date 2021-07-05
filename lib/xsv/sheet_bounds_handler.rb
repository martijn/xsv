# frozen_string_literal: true

module Xsv
  # SheetBoundsHandler scans a sheet looking for the outer bounds of the content within.
  # This is used internally when opening a sheet to deal with worksheets that do not
  # have a correct dimension tag.
  class SheetBoundsHandler < SaxParser
    include Xsv::Helpers

    def self.get_bounds(sheet, workbook)
      rows = 0
      cols = 0

      handler = new(workbook.trim_empty_rows) do |row, col|
        rows = row
        cols = col.zero? ? 0 : col + 1

        return rows, cols
      end

      sheet.rewind

      handler.parse(sheet)

      [rows, cols]
    end

    def initialize(trim_empty_rows, &block)
      @block = block
      @state = nil
      @cell = nil
      @row = nil
      @max_row = 0
      @max_column = 0
      @trim_empty_rows = trim_empty_rows
    end

    def start_element(name, attrs)
      case name
      when 'c'
        @state = name
        @cell = attrs[:r]
      when 'v'
        col = column_index(@cell)
        @max_column = col if col > @max_column
        @max_row = @row if @row > @max_row
      when 'row'
        @state = name
        @row = attrs[:r].to_i
      when 'dimension'
        @state = name

        _first_cell, last_cell = attrs[:ref].split(':')

        if last_cell
          @max_column = column_index(last_cell)
          unless @trim_empty_rows
            @max_row = last_cell[/\d+$/].to_i
            @block.call(@max_row, @max_column)
          end
        end
      end
    end

    def end_element(name)
      @block.call(@max_row, @max_column) if name == 'sheetData'
    end
  end
end
