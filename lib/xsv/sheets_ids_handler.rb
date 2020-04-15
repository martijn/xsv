# frozen_string_literal: true
module Xsv
  # SheetsIdsHandler interprets the relevant parts of workbook.xml
  # This is used internally to get the sheets ids, relationship_ids, and names when opening a workbook.
  class SheetsIdsHandler < Ox::Sax
    def self.get_sheets_ids(io)
      sheets_ids = []
      handler = new do |sheet_ids|
        sheets_ids << sheet_ids
      end

      Ox.sax_parse(handler, io.read)
      return sheets_ids
    end

    # Ox::Sax implementation

    def initialize(&block)
      @block = block
    end

    def start_element(name)
      return @parsing = true if name == :sheets

      return unless name == :sheet

      @sheet_ids = {}
    end

    def attr(name, value)
      return unless @parsing

      case name
        when :name, :sheetId
          @sheet_ids[name] = value
        when :'r:id'
          @sheet_ids[:r_id] = value
      end
    end

    def end_element(name)
      return @parsing = false if name == :sheets

      return unless name == :sheet

      @block.call(@sheet_ids)
    end
  end
end
