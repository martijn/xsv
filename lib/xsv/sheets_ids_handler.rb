# frozen_string_literal: true

module Xsv
  # SheetsIdsHandler interprets the relevant parts of workbook.xml
  # This is used internally to get the sheets ids, relationship_ids, and names, and the properties of the workbook,
  # when opening a workbook.
  class SheetsIdsHandler < SaxParser
    def self.get_sheets_ids(io)
      get_workbook(io).first
    end

    # Returns the sheets ids and the properties of the workbook, the attributes of workbookPr, from one pass over
    # workbook.xml
    def self.get_workbook(io)
      sheets_ids = []

      handler = new { |sheet_ids| sheets_ids << sheet_ids }
      handler.parse(io)

      sheets_ids.each do |sheet|
        sheet[:name].force_encoding(Encoding::UTF_8)
      end

      [sheets_ids, handler.properties]
    end

    # The attributes of workbookPr, empty when it has none
    attr_reader :properties

    def initialize(&block)
      @block = block
      @properties = {}
    end

    def start_element(name, attrs)
      case name
      when "sheet"
        @block.call(attrs.slice(:name, :sheetId, :state, :id))
      when "workbookPr"
        @properties = attrs || {}
      end
    end
  end
end
