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

  # Open the workbook of the given filename, string or buffer.
  # @param filename_or_string [String, IO] the contents or filename of a workbook
  # @param trim_empty_rows [Boolean] Scan sheet for end of content and don't return trailing rows
  # @param parse_headers [Boolean] Call `parse_headers!` on all sheets on load
  # @return [Xsv::Workbook] The workbook instance
  def self.open(filename_or_string, trim_empty_rows: false, parse_headers: false)
    zip = if filename_or_string.is_a?(IO) || filename_or_string.respond_to?(:read) # is it a buffer?
      Zip::File.open_buffer(filename_or_string)
    elsif filename_or_string.start_with?("PK\x03\x04") # is it a string containing a file?
      Zip::File.open_buffer(filename_or_string)
    else # must be a filename
      Zip::File.open(filename_or_string)
    end

    workbook = Xsv::Workbook.new(zip, trim_empty_rows: trim_empty_rows, parse_headers: parse_headers)

    if block_given?
      begin
        yield(workbook)
      ensure
        workbook.close
      end
    else
      workbook
    end
  end
end
