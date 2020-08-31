# frozen_string_literal: true
module Xsv
  # StylesHandler interprets the relevant parts of styles.xml
  # This is used internally when opening a sheet.
  class StylesHandler < SaxParser
    def self.get_styles(io, numFmts)
      @xfs = nil
      @numFmts = nil
      handler = new(numFmts) do |xfs, numFmts|
        @xfs = xfs
        @numFmts = numFmts
      end

      handler.parse(io)

      return @xfs, @numFmts
    end

    def initialize(numFmts, &block)
      @block = block
      @state = nil
      @xfs = []
      @numFmts = numFmts
    end

    def start_element(name, attrs)
      case name
      when "cellXfs"
        @state = "cellXfs"
      when "xf"
        @xfs << attrs.map { |k, v| [k.to_sym, v] }.to_h if @state == "cellXfs"
      when "numFmt"
        attr_h = attrs.map { |k, v| [k.to_sym, v] }.to_h
        @numFmts[attr_h[:numFmtId].to_i] = attr_h[:formatCode]
      end
    end

    def end_element(name)
      if name == "styleSheet"
        @block.call(@xfs, @numFmts)
      elsif name == "cellXfs"
        @state = nil
      end
    end
  end
end
