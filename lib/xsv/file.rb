require 'nokogiri'
require 'zip'

module Xsv
  class File

    attr_reader :sheets, :shared_strings

    def initialize(file)
      @zip = Zip::File.open(file)
      @sheets = []
      fetch_shared_strings
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

    def fetch_sheets
      @zip.glob("xl/worksheets/sheet*.xml").sort do |entry|
        entry.name.scan(/\d+/).first.to_i
      end.each do |entry|
        @sheets << Xsv::Sheet.new(self, Nokogiri::XML(entry.get_input_stream))
      end
    end
  end
end
