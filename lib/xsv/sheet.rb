module Xsv
  class Sheet
    include Xsv::Helpers

    attr_reader :xml, :mode

    def initialize(workbook, xml)
      @workbook = workbook
      @xml = xml
      @headers = []
      @mode = :array

      dimension = xml.css("dimension").first

      if dimension
        _firstCell, lastCell = dimension["ref"].split(":")
      end

      if lastCell
        # Assume the dimension reflects the content
        @column_count = column_index(lastCell) + 1
      else
        # Find the last cell in every row that has a value
        rightmost_cells = @xml.xpath("//xmlns:row/xmlns:c[*[local-name() = 'v']][last()]").map { |c| column_index(c["r"]) }
        @column_count = rightmost_cells.max + 1

      end

      # Find the last row that contains actual values
      @last_row = @xml.xpath("//xmlns:row[*[xmlns:v]][last()]").first["r"].to_i
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

        # Do not return empty trailing rows
        break if row_index == @last_row
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
      @headers = parse_headers

      @mode = :hash

      true
    end

    private

    def parse_headers
      parse_row(@xml.css("sheetData row").first)
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

      xml.css("c").first(@column_count).each do |c_xml|
        value = case c_xml["t"]
          when "s"
            @workbook.shared_strings[c_xml.css("v").inner_text.to_i]
          when "str"
            c_xml.css("v").inner_text.to_s
          when "e" # N/A
            nil
          when nil
            v = c_xml.css("v").first

            if v.nil?
              nil
            elsif c_xml["s"]
              value = parse_number(v.inner_text)

              style = @workbook.xfs[c_xml["s"].to_i]
              numFmtId = style[:numFmtId].to_i
              numFmt = @workbook.numFmts[numFmtId]
              if numFmtId == 0
                value
              elsif is_datetime_format?(numFmt)
                parse_datetime(value)
              elsif is_date_format?(numFmt)
                parse_date(value)
              elsif is_time_format?(numFmt)
                parse_time(value)
              else
                value
              end
            else
              parse_number(v.inner_text)
            end
          else
            raise Xsv::Error, "Encountered unknown column type #{c_xml["t"]}"
          end

        # Determine column position and pad row with nil values
        col_index = column_index(c_xml["r"])

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
