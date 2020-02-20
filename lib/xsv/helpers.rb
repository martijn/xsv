require 'date'

module Xsv
  module Helpers
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
      49 => "@",
    }

    # Return the index number for the given Excel column name
    def column_index(col)
      val = 0
      while col.length > 0
        val *= 26
        val += (col[0].ord - "A".ord + 1)
        col = col[1..-1]
      end
      return val - 1
    end

    # Return a Date for the given Excel date value
    def parse_date(number)
      Date.new(1899, 12, 30) + number
    end

    # Tests if the given format string is a date
    def is_date_format?(format)
      # If it contains at least 2 sequences of d's, m's or y's it's a date!
      format.scan(/[dmy]+/).length > 1
    end
  end
end
