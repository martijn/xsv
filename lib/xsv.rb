require "date"
require "ox"

require "xsv/helpers"
require "xsv/shared_strings_parser"
require "xsv/sheet"
require "xsv/sheet_rows_handler"
require "xsv/version"
require "xsv/workbook"

module Xsv
  class Error < StandardError; end
  # An AssertionFailed error indicates an unexpected condition, meaning a bug
  # or misinterpreted .xlsx document
  class AssertionFailed < StandardError; end
end
