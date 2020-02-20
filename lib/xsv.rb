require "date"

require "xsv/helpers"
require "xsv/sheet"
require "xsv/version"
require "xsv/workbook"

module Xsv
  class Error < StandardError; end
  # An AssertionFailed error indicates an unexpected condition, meaning a bug
  # or misinterpreted .xlsx document
  class AssertionFailed < StandardError; end
end
