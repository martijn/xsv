# frozen_string_literal: true
require 'zip'

module Xsv
  class Workbook

    attr_reader :sheets, :shared_strings, :xfs, :numFmts, :trim_empty_rows

    # Open the workbook of the given filename, string or buffer
    def self.open(data, **kws)
      if data.is_a?(IO)
        @workbook = self.new(Zip::File.open_buffer(data), **kws)
      elsif data.start_with?("PK\x03\x04")
        @workbook = self.new(Zip::File.open_buffer(data), **kws)
      else
        @workbook = self.new(Zip::File.open(data), **kws)
      end
    end

    # Open a workbook from an instance of Zip::File
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
      fetch_sheets
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id}>"
    end

    def close
      @zip.close
      @sheets = nil
      @xfs = nil
      @numFmts = nil
      @shared_strings = nil
    end

    private

    def fetch_shared_strings
      stream = @zip.glob("xl/sharedStrings.xml").first.get_input_stream
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
        @sheets << Xsv::Sheet.new(self, entry.get_input_stream)
      end
    end
  end
end
