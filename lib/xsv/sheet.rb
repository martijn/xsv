# frozen_string_literal: true
module Xsv
  class Sheet
    include Enumerable
    include Xsv::Helpers

    attr_reader :mode

    # Set a number of rows to skip at the top of the sheet (header row offset)
    attr_accessor :row_skip

    def initialize(workbook, io)
      @workbook = workbook
      @io = io
      @headers = []
      @mode = :array
      @row_skip = 0

      @last_row, @column_count = SheetBoundsHandler.get_bounds(@io, @workbook)
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id}>"
    end

    # Iterate over rows
    def each_row
      @io.rewind

      handler = SheetRowsHandler.new(@mode, empty_row, @workbook, @row_skip, @last_row) do |row|
        yield(row)
      end

      Ox.sax_parse(handler, @io)

      true
    end

    alias each each_row

    # Get row by number, starting at 0
    def [](number)
      each_with_index do |row, i|
        return row if i == number
      end

      return empty_row
    end

    # Load headers in the top row of the worksheet. After parsing of headers
    # all methods return hashes instead of arrays
    def parse_headers!
      @headers = parse_headers
      @mode = :hash

      true
    end

    def headers
      if @headers.any?
        @headers
      else
        parse_headers
      end
    end

    private

    def parse_headers
      if @mode == :array
        first
      elsif @mode == :hash
        @mode = :array
        headers.tap { @mode = :hash }
      end
    end

    def empty_row
      case @mode
      when :array
        [nil] * @column_count
      when :hash
        @headers.zip([]).to_h
      end
    end
  end
end
