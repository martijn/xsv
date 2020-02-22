module Xsv
  # SheetBoundsHandler scans a sheet looking for the outer bounds of the content within
  class SheetBoundsHandler < Ox::Sax
    include Xsv::Helpers

    def self.get_bounds(sheet)
      rows = 0
      cols = 0

      handler = new do |row, col|
        rows = row
        cols = col == 0 ? 0 : col + 1
      end

      sheet.rewind
      Ox.sax_parse(handler, sheet)

      return rows, cols
    end

    # Ox::Sax implementation

    def initialize(&block)
      @block = block
      @state = nil
      @cell = nil
      @row = nil
      @maxRow = 0
      @maxColumn = 0
    end

    def start_element(name)
      if name == :dimension
        @state = name
      elsif name == :row
        @state = name
        @row = {}
      elsif name == :c
        @state = name
        @cell = {}
      elsif name == :v
        col = column_index(@cell)
        @maxColumn = col if col > @maxColumn
        @maxRow = @row if @row > @maxRow
      end
    end

    def end_element(name)
      if name == :sheetData
        @block.call(@maxRow, @maxColumn)
      end
    end

    def attr(name, value)
      if @state == :dimension && name == :ref
        _firstCell, lastCell = value.split(":")

        if lastCell
          # This is probably right, but we'll let the scan continue to see
          # if the values are exceeded
          @maxColumn = column_index(lastCell)
        end
      elsif @state == :c && name == :r
        @cell = value
      elsif @state == :row && name == :r
        @row = value.to_i
      end
    end
  end
end
