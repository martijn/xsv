module Xsv
  # StylesHandler interprets the relevant parts of styles.xml
  class StylesHandler < Ox::Sax
    def self.get_styles(io, numFmts)
      @xfs = nil
      @numFmts = nil
      handler = new(numFmts) do |xfs, numFmts|
         @xfs = xfs
         @numFmts = numFmts
      end

      Ox.sax_parse(handler, io)
      return @xfs, @numFmts
    end

    # Ox::Sax implementation

    def initialize(numFmts, &block)
      @block = block
      @state = nil
      @xfs = []
      @numFmts = numFmts

      @xf = {}
      @numFmt = {}
    end

    def start_element(name)
      case name
      when :cellXfs, :numFmts
        @state = name
      when :xf
        @xf = {}
      when :numFmt
        @numFmt = {}
      end
    end

    def attr(name, value)
      case @state
      when :cellXfs
        @xf[name] = value
      when :numFmts
        @numFmt[name] = value
      end
    end

    def end_element(name)
      if @state == :cellXfs && name == :xf
        @xfs << @xf
      elsif @state == :numFmts && name == :numFmt
        @numFmts[@numFmt[:numFmtId].to_i] = @numFmt[:formatCode]
      elsif name == :styleSheet
        @block.call(@xfs, @numFmts)
      end
    end
  end
end
