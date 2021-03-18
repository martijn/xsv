# frozen_string_literal: true

module Xsv
  # Sheet represents a single worksheet from a workbook and is normally accessed through {Workbook#sheets}
  #
  # Xsv is designed for worksheets with a single table of data, optionally with a header row. Because sheet implements
  # {Enumerable} the rows in the worksheet can be iterated over using methods such as `#each` and `#map`
  #
  # By default Sheet will return rows as arrays. But by calling the {#parse_headers!} method the first row of the sheet
  # will be parsed and Sheet will switch to hash mode, returning each row as a hash with the values from the first
  # row as keys.
  #
  # If the sheet contains leading data before the first row of data or the header row, this can be skipped by setting the
  # {row_skip} attribute.
  class Sheet
    include Enumerable
    include Xsv::Helpers

    # Returns the current mode. Call {#parse_headers!} to switch to `:hash` mode
    # @return [Symbol] `:hash` or `:array`
    attr_reader :id, :mode, :name

    # Set a number of rows to skip at the top of the sheet (header row offset).
    # For hash mode, do not skip the header row as this will be automatically
    # skipped.
    attr_accessor :row_skip

    # Create a new instance of Sheet. This is used internally by the {Workbook}.
    # There is no need to create Sheets from application code.
    #
    # @param workbook [Workbook] The Workbook with shared data such as shared strings and styles
    # @param io [IO] A handle to an open worksheet XML file
    # @param size [Number] size of the XML file
    def initialize(workbook, io, size, ids)
      @workbook = workbook
      @id = ids[:sheetId].to_i
      @io = io
      @name = ids[:name]
      @size = size
      @headers = []
      @mode = :array
      @row_skip = 0
      @hidden = ids[:state] == 'hidden'

      @last_row, @column_count = SheetBoundsHandler.get_bounds(@io, @workbook)
    end

    # @return [String]
    def inspect
      "#<#{self.class.name}:#{object_id}>"
    end

    # Returns true if the worksheet is hidden
    def hidden?
      @hidden
    end

    # Iterate over rows, returning either hashes or arrays based on the current mode.
    def each_row(&block)
      @io.rewind

      handler = SheetRowsHandler.new(@mode, empty_row, @workbook, @row_skip, @last_row, &block)

      handler.parse(@io)

      true
    end

    alias each each_row

    # Get row by number, starting at 0. Returns either a hash or an array based on the current row.
    # If the specified index is out of bounds an empty row is returned.
    def [](number)
      each_with_index do |row, i|
        return row if i == number
      end

      empty_row
    end

    # Load headers in the top row of the worksheet. After parsing of headers
    # all methods return hashes instead of arrays
    # @return [self]
    def parse_headers!
      @headers = parse_headers
      @mode = :hash

      self
    end

    # Return the headers of the sheet as an array
    def headers
      if @headers.any?
        @headers
      else
        parse_headers
      end
    end

    private

    def parse_headers
      case @mode
      when :array
        first
      when :hash
        @mode = :array
        headers.tap { @mode = :hash }
      end || []
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
