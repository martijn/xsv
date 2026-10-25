# frozen_string_literal: true

module Xsv
  # WorkbookPropertiesHandler reads the properties of the workbook, the attributes of workbookPr in workbook.xml.
  # This is used internally to find out which date system the workbook uses when opening a workbook.
  class WorkbookPropertiesHandler < SaxParser
    def self.get_properties(io)
      properties = {}

      new { |attrs| properties = attrs }.parse(io)

      properties
    end

    def initialize(&block)
      @block = block
    end

    def start_element(name, attrs)
      @block.call(attrs) if name == "workbookPr"
    end
  end
end
