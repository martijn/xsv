module Xsv
  class Sheet
    include Xsv::Helpers

    attr_reader :xml, :mode

    # Set a number of rows to skip at the top of the sheet (header row offset)
    attr_accessor :row_skip

    def initialize(workbook, xml)
      @workbook = workbook
      @xml = xml
      @headers = []
      @mode = :array
      @row_skip = 0

      @has_cells = !xml.at_css("sheetData c").nil?

      if @has_cells
        @column_count, @last_row = get_sheet_dimensions
      else
        @column_count = 0
        @last_row = 0
      end
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id}>"
    end

    # Iterate over rows
    def each_row
      row_index = 0 - @row_skip

      @xml.css("sheetData row").each do |row_xml|
        if row_index < 0
          row_index += 1
          next
        end

        row_index += 1

        next if row_index == 1 && @mode == :hash

        # pad empty rows
        while row_index < row_xml["r"].to_i - @row_skip do
          yield(empty_row)
          row_index += 1
        end

        yield(parse_row(row_xml))

        # Do not return empty trailing rows
        break if row_index == @last_row - @row_skip
      end

      true
    end

    # Get row by number, starting at 0
    def [](number)
      row_xml = xml.at_css("sheetData row[r=#{number + @row_skip + 1}]")

      if row_xml
        parse_row(row_xml)
      else
        empty_row
      end
    end

    # Load headers in the top row of the worksheet. After parsing of headers
    # all methods return hashes instead of arrays
    def parse_headers!
      @headers = parse_headers
      @mode = :hash

      true
    end

    def headers
      if @headers.any?
        @headers
      else
        parse_headers
      end
    end

    private

    def parse_headers
      parse_row(@xml.css("sheetData row")[@row_skip], :array)
    end

    def empty_row
      case @mode
      when :array
        [nil] * @column_count
      when :hash
        @headers.zip([]).to_h
      end
    end

    def parse_row(xml, mode = nil)
      mode ||= @mode
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
            v = c_xml.at_css("v")

            if v.nil?
              nil
            elsif c_xml["s"]
              style = @workbook.xfs[c_xml["s"].to_i]
              numFmt = @workbook.numFmts[style[:numFmtId].to_i]

              parse_number_format(v.inner_text, numFmt)
            else
              parse_number(v.inner_text)
            end
          else
            raise Xsv::Error, "Encountered unknown column type #{c_xml["t"]}"
          end

        # Determine column position and pad row with nil values
        col_index = column_index(c_xml["r"])

        case mode
        when :array
          row[col_index] = value
        when :hash
          row[@headers[col_index]] = value
        end
      end

      row
    end

    # Read or estimate outer bounds of sheet
    def get_sheet_dimensions
      dimension = xml.at_css("dimension")

      if dimension
        _firstCell, lastCell = dimension["ref"].split(":")
      end

      if lastCell
        # Assume the dimension reflects the content
        column_count = column_index(lastCell) + 1
      else
        # Find the last cell in every row that has a value
        rightmost_cells = @xml.xpath("//xmlns:row/xmlns:c[*[local-name() = 'v']][last()]").map { |c| column_index(c["r"]) }
        column_count = rightmost_cells.max + 1
      end

      # Find the last row that contains actual values
      last_row = @xml.at_xpath("//xmlns:row[*[xmlns:v]][last()]")["r"].to_i

      return [column_count, last_row]
    end
  end
end
