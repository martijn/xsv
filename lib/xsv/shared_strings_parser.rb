# frozen_string_literal: true
module Xsv
  # Interpret the sharedStrings.xml file from the workbook
  # This is used internally when opening a sheet.
  class SharedStringsParser < SaxParser
    def self.parse(io)
      strings = []
      new { |s| strings << s }.parse(io)
      return strings
    end

    def initialize(&block)
      @block = block
      @state = nil
    end

    def start_element(name, attrs)
      case name
      when "si"
        @current_string = ""
      when "t"
        @state = name
      end
    end

    def characters(value)
      @current_string += value if @state == "t"
    end

    def end_element(name)
      case name
      when "si"
        @block.call(@current_string)
      when "t"
        @state = nil
      end
    end
  end
end
