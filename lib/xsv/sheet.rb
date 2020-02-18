module Xsv
  class Sheet
    attr_reader :xml

    def initialize(sheet, xml)
      @sheet = sheet
      @xml = xml
    end

    def each_row(read_headers: false)
      @xml.css("sheetData row").each do |row_xml|
        yield(row_xml.css("c").map do |c_xml|
          case c_xml["t"]
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
        end)
      end

      true
    end
  end
end
