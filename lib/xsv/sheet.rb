module Xsv
  class Sheet
    attr_reader :xml

    def initialize(sheet, xml)
      @sheet = sheet
      @xml = xml
      @headers = []
    end

    def each_row(read_headers: false)
      if read_headers
        @headers = parse_row(@xml.css("sheetData row").first)
      end

      @xml.css("sheetData row").each do |row_xml|
        yield(parse_row(row_xml))
      end

      true
    end

    private

    def parse_row(xml)
      if @headers.any?
        row = {}
      else
        row = []
      end

      xml.css("c").each_with_index do |c_xml, i|
        next if @headers.any? && i == 0

        value = case c_xml["t"]
          when "s"
            @sheet.shared_strings[c_xml.css("v").inner_text.to_i]
          when "str"
            c_xml.css("v").inner_text
          when "e" # N/A
            nil
          when nil
            c_xml.css("v").inner_text.to_i
          else
            raise Xsv::Error, "Encountered unknown column type #{c_xml["t"]}"
          end

        if @headers.any?
          row[@headers[i]] = value
        else
          row << value
        end
      end

      row
    end
  end
end
