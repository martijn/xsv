require "test_helper"

class SharedStringsParserTest < Minitest::Test
  def test_parser
    @file = File.open("test/files/sharedStrings.xml")

    strings = []

    strings = Xsv::SharedStringsParser.parse(@file)

    assert_includes strings, "This sharedString is split down the middle"
    refute_includes strings, ""
    refute_includes strings, nil

    assert_equal 33, strings.length
  end

  def test_whitespace
    @file = File.open("test/files/sharedStrings-whitespace.xml")

    strings = []

    strings = Xsv::SharedStringsParser.parse(@file)

    assert_includes strings, "A       B"
    assert_includes strings, "   Leading"
    assert_includes strings, "Trailing      "
  end

  def test_utf8
    @workbook = Xsv::Workbook.open("test/files/utf8.xlsx")

    utf8 = @workbook.sheets[0][0][0]

    assert_equal Encoding::UTF_8, utf8.encoding
  end
end
