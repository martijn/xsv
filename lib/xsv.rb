# frozen_string_literal: true
require "date"

require "xsv/helpers"
require "xsv/sax_parser"
require "xsv/relationships_handler"
require "xsv/shared_strings_parser"
require "xsv/sheet"
require "xsv/sheet_bounds_handler"
require "xsv/sheet_rows_handler"
require "xsv/sheets_ids_handler"
require "xsv/styles_handler"
require "xsv/version"
require "xsv/workbook"

# XSV is a fast, lightweight parser for Office Open XML spreadsheet files
# (commonly known as Excel or .xlsx files). It strives to be minimal in the
# sense that it provides nothing a CSV reader wouldn't, meaning it only
# deals with minimal formatting and cannot create or modify documents.
module Xsv
  class Error < StandardError; end

  # An AssertionFailed error indicates an unexpected condition, meaning a bug
  # or misinterpreted .xlsx document
  class AssertionFailed < StandardError; end
end
