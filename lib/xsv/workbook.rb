# frozen_string_literal: true
require "zip"

module Xsv
  # An OOXML Spreadsheet document is called a Workbook. A Workbook consists of
  # multiple Sheets that are available in the array that's accessible through {#sheets}
  class Workbook

    # Access the Sheet objects contained in the workbook
    # @return [Array<Sheet>]
    attr_reader :sheets

    attr_reader :shared_strings, :xfs, :numFmts, :trim_empty_rows

    # Open the workbook of the given filename, string or buffer. For additional
    # options see {.initialize}
    def self.open(data, **kws)
      if data.is_a?(IO) || data.respond_to?(:read) # is it a buffer?
        @workbook = self.new(Zip::File.open_buffer(data), **kws)
      elsif data.start_with?("PK\x03\x04") # is it a string containing a filename?
        @workbook = self.new(Zip::File.open_buffer(data), **kws)
      else # must be a filename
        @workbook = self.new(Zip::File.open(data), **kws)
      end
    end

    # Open a workbook from an instance of {Zip::File}. Generally it's recommended
    # to use the {.open} method instead of the constructor.
    #
    # Options:
    #
    #    trim_empty_rows (false) Scan sheet for end of content and don't return trailing rows
    #
    def initialize(zip, trim_empty_rows: false)
      @zip = zip
      @trim_empty_rows = trim_empty_rows

      @sheets = []
      @xfs = []
      @numFmts = Xsv::Helpers::BUILT_IN_NUMBER_FORMATS.dup

      fetch_shared_strings
      fetch_styles
      fetch_sheets_ids
      fetch_relationships
      fetch_sheets
    end

    # @return [String]
    def inspect
      "#<#{self.class.name}:#{self.object_id}>"
    end

    # Close the handle to the workbook file and leave all resources for the GC to collect
    # @return [true]
    def close
      @zip.close
      @sheets = nil
      @xfs = nil
      @numFmts = nil
      @relationships = nil
      @shared_strings = nil
      @sheets_ids = nil

      true
    end

    # Returns an array of sheets for the case of same name sheets.
    # @param [String] name
    # @return [Array<Xsv::Sheet>]
    def sheets_by_name(name)
      @sheets.select { |s| s.name == name }
    end

    private

    def fetch_shared_strings
      handle = @zip.glob("xl/sharedStrings.xml").first
      return if handle.nil?

      stream = handle.get_input_stream
      @shared_strings = SharedStringsParser.parse(stream)

      stream.close
    end

    def fetch_styles
      stream = @zip.glob("xl/styles.xml").first.get_input_stream

      @xfs, @numFmts = StylesHandler.get_styles(stream, @numFmts)
    end

    def fetch_sheets
      @zip.glob("xl/worksheets/sheet*.xml").sort do |a, b|
        a.name[/\d+/].to_i <=> b.name[/\d+/].to_i
      end.each do |entry|
        rel = @relationships.detect { |r| entry.name.end_with?(r[:Target]) && r[:Type].end_with?("worksheet") }
        sheet_ids = @sheets_ids.detect { |i| i[:"r:id"] == rel[:Id] }
        @sheets << Xsv::Sheet.new(self, entry.get_input_stream, entry.size, sheet_ids)
      end
    end

    def fetch_sheets_ids
      stream = @zip.glob("xl/workbook.xml").first.get_input_stream
      @sheets_ids = SheetsIdsHandler.get_sheets_ids(stream)

      stream.close
    end

    def fetch_relationships
      stream = @zip.glob("xl/_rels/workbook.xml.rels").first.get_input_stream
      @relationships = RelationshipsHandler.get_relations(stream)

      stream.close
    end
  end
end
