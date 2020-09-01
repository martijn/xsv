# frozen_string_literal: true
module Xsv
  # SheetsIdsHandler interprets the relevant parts of workbook.xml
  # This is used internally to get the sheets ids, relationship_ids, and names when opening a workbook.
  class SheetsIdsHandler < SaxParser
    def self.get_sheets_ids(io)
      sheets_ids = []

      new { |sheet_ids| sheets_ids << sheet_ids }.parse(io)

      return sheets_ids
    end

    def initialize(&block)
      @block = block
    end

    def start_element(name, attrs)
      @block.call(attrs.slice(*%i{name sheetId state r:id})) if name == "sheet"
    end
  end
end
