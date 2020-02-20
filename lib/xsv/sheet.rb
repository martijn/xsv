module Xsv
  class Sheet
    include Xsv::Helpers

    attr_reader :xml

    def initialize(workbook, xml)
      @workbook = workbook
      @xml = xml
      @headers = []
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id}>"
    end

    # Iterate over rows. Returns an array if read_headers is false, or a hash
    # with first row values as keys if read_headers is true
    def each_row(read_headers: false)
      @parse_headers if read_headers

      @xml.css("sheetData row").each_with_index do |row_xml, i|
        next if i == 0 && @headers.any?

        yield(parse_row(row_xml))
      end

      true
    end

    # Get row by number, starting at 0
    def [](number)
      parse_row(@xml.css("sheetData row:nth-child(#{number + 1})").first)
    end

    # Load headers in the top row of the worksheet. After parsing of headers
    # all methods return hashes instead of arrays
    def parse_headers!
      parse_headers

      true
    end

    private

    def parse_headers
      @headers = parse_row(@xml.css("sheetData row").first)
    end

    def parse_row(xml)
      if @headers.any?
        row = {}
      else
        row = []
      end

      next_index = 0

      xml.css("c").each do |c_xml|
        value = case c_xml["t"]
          when "s"
            @workbook.shared_strings[c_xml.css("v").inner_text.to_i]
          when "str"
            c_xml.css("v").inner_text.to_s
          when "e" # N/A
            nil
          when nil
            value = c_xml.css("v").inner_text.to_i

            if c_xml["s"]
              style = @workbook.xfs[c_xml["s"].to_i]
              numFmtId = style[:numFmtId].to_i
              if numFmtId == 0
                value
              elsif is_date_format?(BUILT_IN_NUMBER_FORMATS[numFmtId])
                parse_date(value)
              else
                value
              end
            else
              value
            end
          else
            raise Xsv::Error, "Encountered unknown column type #{c_xml["t"]}"
          end

        # Determine column position and pad row with nil values
        col_index = column_index(c_xml["r"].scan(/^[A-Z]+/).first)

        (col_index - next_index).times do
          if @headers.any?
            row[@headers[next_index]] = nil
          else
            row << nil
          end
          next_index += 1
        end

        if @headers.any?
          row[@headers[next_index]] = value
        else
          row << value
        end

        next_index += 1
      end

      row
    end
  end
end
