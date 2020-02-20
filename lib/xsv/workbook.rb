require 'nokogiri'
require 'zip'

module Xsv
  class Workbook

    attr_reader :sheets, :shared_strings, :xfs, :numFmts

    # Open the workbook of the given filename
    def self.open(file)
      @workbook = self.new(Zip::File.open(file))
    end

    # Open a workbook from an instance of Zip::File
    def initialize(zip)
      @zip = zip

      @sheets = []
      @xfs = []
      @numFmts = Xsv::Helpers::BUILT_IN_NUMBER_FORMATS

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
      xml = Nokogiri::XML(stream)
      expected_count = xml.css("sst").first["uniqueCount"].to_i
      @shared_strings = xml.css("sst si t").map(&:inner_text)

      if @shared_strings.count != expected_count
        raise Xsv::Error, "Mismatch in shared strings count! #{expected_count} <> #{@shared_strings.count}"
      end

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
        a.name.scan(/\d+/).first.to_i <=> b.name.scan(/\d+/).first.to_i
      end.each do |entry|
        @sheets << Xsv::Sheet.new(self, Nokogiri::XML(entry.get_input_stream))
      end
    end
  end
end
