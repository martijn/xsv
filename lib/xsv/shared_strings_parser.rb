# frozen_string_literal: true

module Xsv
  # Interpret the sharedStrings.xml file from the workbook
  # This is used internally when opening a sheet.
  class SharedStringsParser < SaxParser
    def self.parse(io)
      strings = []
      new { |s| strings << s }.parse(io)
      strings
    end

    def initialize(&block)
      @block = block
      @state = nil
      @skip = false
    end

    def start_element(name, _attrs)
      case name
      when "si"
        @current_string = ""
        @skip = false
      when "rPh"
        @skip = true
      when "t"
        @state = name
      end
    end

    def characters(value)
      if @state == "t" && !@skip
        @current_string += value
      end
    end

    def end_element(name)
      case name
      when "si"
        @block.call(@current_string)
      when "rPh"
        @skip = false
      when "t"
        @state = nil
      end
    end
  end
end
