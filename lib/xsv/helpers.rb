# frozen_string_literal: true

module Xsv
  module Helpers
    # The default OOXML Spreadheet number formats according to the ECMA standard
    # User formats are appended from index 174 onward
    BUILT_IN_NUMBER_FORMATS = {
      1 => "0",
      2 => "0.00",
      3 => "#, ##0",
      4 => "#, ##0.00",
      5 => "$#, ##0_);($#, ##0)",
      6 => "$#, ##0_);[Red]($#, ##0)",
      7 => "$#, ##0.00_);($#, ##0.00)",
      8 => "$#, ##0.00_);[Red]($#, ##0.00)",
      9 => "0%",
      10 => "0.00%",
      11 => "0.00E+00",
      12 => "# ?/?",
      13 => "# ??/??",
      14 => "m/d/yyyy",
      15 => "d-mmm-yy",
      16 => "d-mmm",
      17 => "mmm-yy",
      18 => "h:mm AM/PM",
      19 => "h:mm:ss AM/PM",
      20 => "h:mm",
      21 => "h:mm:ss",
      22 => "m/d/yyyy h:mm",
      37 => "#, ##0_);(#, ##0)",
      38 => "#, ##0_);[Red](#, ##0)",
      39 => "#, ##0.00_);(#, ##0.00)",
      40 => "#, ##0.00_);[Red](#, ##0.00)",
      45 => "mm:ss",
      46 => "[h]:mm:ss",
      47 => "mm:ss.0",
      48 => "##0.0E+0",
      49 => "@"
    }.freeze

    MINUTE = 60
    HOUR = 3600
    A_CODEPOINT = "A".ord.freeze
    # The epoch for all dates in OOXML Spreadsheet documents
    EPOCH = Date.new(1899, 12, 30).freeze

    # Return the index number for the given Excel column name (i.e. "A1" => 0)
    # @param col [String] Column name in A1 notation
    def column_index(col)
      chars = col.bytes
      sum = 0
      while (char = chars.delete_at(0))
        break sum - 1 if char < A_CODEPOINT # reached the number

        sum = sum * 26 + (char - A_CODEPOINT + 1)
      end
    end

    # Return a Date for the given Excel date value
    def parse_date(number)
      EPOCH + number
    end

    # Return a time as a string for the given Excel time value
    def parse_time(number)
      # Disregard date part
      number -= number.truncate if number.positive?

      base = number * 24

      hours = base.truncate
      minutes = ((base - hours) * 60).round

      # Compensate for rounding errors
      if minutes >= 60
        hours += (minutes / 60)
        minutes %= 60
      end

      format("%02d:%02d", hours, minutes)
    end

    # Returns a time including a date as a {Time} object
    def parse_datetime(number)
      date_base = number.truncate
      time = parse_date(date_base).to_time

      time_base = (number - date_base) * 24

      hours = time_base.truncate
      minutes = (time_base - hours) * 60

      time + hours * HOUR + minutes.round * MINUTE
    end

    # Returns a number as either Integer or Float
    def parse_number(string)
      if string.include? "."
        string.to_f
      elsif string.include? "E"
        Complex(string).to_f
      else
        string.to_i
      end
    end

    # Apply date or time number formats, if applicable
    def parse_number_format(number, format)
      number = parse_number(number) # number is always a string since it comes out of the Sax Parser

      return number if format.nil?

      is_date_format = format.scan(/[dmy]+/).length > 1
      is_time_format = format.scan(/[hms]+/).length > 1

      if !is_date_format && !is_time_format
        number
      elsif is_date_format && is_time_format
        parse_datetime(number)
      elsif is_date_format
        parse_date(number)
      elsif is_time_format
        parse_time(number)
      end
    end
  end
end
