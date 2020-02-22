require 'nokogiri'
require 'zip'

module Xsv
  class Workbook

    attr_reader :sheets, :shared_strings, :xfs, :numFmts

    # Open the workbook of the given filename, string or buffer
    def self.open(data)
      if data.is_a?(IO)
        @workbook = self.new(Zip::File.open_buffer(data))
      elsif data.start_with?("PK\x03\x04")
        @workbook = self.new(Zip::File.open_buffer(data))
      else
        @workbook = self.new(Zip::File.open(data))
      end
    end

    # Open a workbook from an instance of Zip::File
    def initialize(zip)
      @zip = zip

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

    private

    def fetch_shared_strings
      stream = @zip.glob("xl/sharedStrings.xml").first.get_input_stream
      @shared_strings = SharedStringsParser.parse(stream)

      stream.close
    end

    def fetch_styles
      stream = @zip.glob("xl/styles.xml").first.get_input_stream
      xml = Nokogiri::XML(stream)

      xml.css("cellXfs xf").each do |xf|
        @xfs << xf.attributes.map { |k, v| [k.to_sym, v.value] }.to_h
      end

      xml.css("numFmts numFmt").each do |numFmt|
        @numFmts[numFmt["numFmtId"].to_i] = numFmt["formatCode"]
      end
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
