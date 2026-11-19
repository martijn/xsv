require "./test/test_helper"

class StylesHandlerTest < Minitest::Test
  def test_overlapping_parses_keep_their_own_styles
    date_styles = styles_xml("yyyy-mm-dd")
    number_styles = styles_xml("0.00")
    handler = Class.new(Xsv::StylesHandler) do
      define_method(:parse) do |io|
        super(io)
        self.class.get_styles(number_styles) if io.equal?(date_styles)
      end
    end

    xfs, num_fmts = handler.get_styles(date_styles)

    assert_equal [{numFmtId: 164}], xfs
    assert_equal "yyyy-mm-dd", num_fmts[164]
  end

  def test_truncated_styles_raise_after_a_successful_parse
    xml = styles_xml("yyyy-mm-dd")
    Xsv::StylesHandler.get_styles(xml)

    error = assert_raises(Xsv::Error) do
      Xsv::StylesHandler.get_styles(xml.delete_suffix("</styleSheet>\n"))
    end

    assert_equal "styles.xml has no closing </styleSheet>", error.message
  end

  def test_self_closing_stylesheet_returns_empty_styles_and_built_in_formats
    ["<styleSheet/>", '<x:styleSheet xmlns:x="urn:spreadsheet" />'].each do |xml|
      xfs, num_fmts = Xsv::StylesHandler.get_styles(xml)

      assert_empty xfs
      assert_equal Xsv::Helpers::BUILT_IN_NUMBER_FORMATS, num_fmts
    end
  end

  private

  def styles_xml(format)
    <<~XML
      <styleSheet>
        <numFmts><numFmt numFmtId="164" formatCode="#{format}"/></numFmts>
        <cellXfs><xf numFmtId="164"/></cellXfs>
      </styleSheet>
    XML
  end
end
