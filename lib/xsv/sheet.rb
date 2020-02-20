module Xsv
  class Sheet
    include Xsv::Helpers

    attr_reader :xml, :mode

    def initialize(workbook, xml)
      @workbook = workbook
      @xml = xml
      @headers = []

      # Determine number of columns
      bounds = @xml.css("cols col").map { |c| [c["min"].to_i, c["max"].to_i] }.flatten
      @column_count = (bounds.max - bounds.min) + 1

      @mode = :array
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id}>"
    end

    # Iterate over rows
    def each_row
      row_index = 0
      @xml.css("sheetData row").each do |row_xml|
        row_index += 1

        next if row_index == 1 && @mode == :hash

        # pad empty rows
        while row_index < row_xml["r"].to_i do
          yield(empty_row)
          row_index += 1
        end

        yield(parse_row(row_xml))
      end

      true
    end

    # Get row by number, starting at 0
    def [](number)
      row_xml = xml.css("sheetData row[r=#{number + 1}]").first

      if row_xml
        parse_row(row_xml)
      else
        empty_row
      end
    end

    # Load headers in the top row of the worksheet. After parsing of headers
    # all methods return hashes instead of arrays
    def parse_headers!
      @mode = :array
      parse_headers

      @mode = :hash

      true
    end

    private

    def parse_headers
      @headers = parse_row(@xml.css("sheetData row").first)
    end

    def empty_row
      case @mode
      when :array
        [nil] * @column_count
      when :hash
        @headers.zip([]).to_h
      end
    end

    def parse_row(xml)
      row = empty_row

      xml.css("c").each do |c_xml|
        value = case c_xml["t"]
          when "s"
            @workbook.shared_strings[c_xml.css("v").inner_text.to_i]
          when "str"
            c_xml.css("v").inner_text.to_s
          when "e" # N/A
            nil
          when nil
            value = parse_number(c_xml.css("v").inner_text)

            if c_xml["s"]
              style = @workbook.xfs[c_xml["s"].to_i]
              numFmtId = style[:numFmtId].to_i
              if numFmtId == 0
                value
              elsif is_date_format?(@workbook.numFmts[numFmtId])
                parse_date(value)
              elsif is_time_format?(@workbook.numFmts[numFmtId])
                parse_time(value)
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

        case @mode
        when :array
          row[col_index] = value
        when :hash
          row[@headers[col_index]] = value
        end
      end

      row
    end
  end
end
