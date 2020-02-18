module Xsv
  module Helpers
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
  end
end
