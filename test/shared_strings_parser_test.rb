require "./test/test_helper"

class SharedStringsParserTest < Minitest::Test
  def test_parser
    @file = File.open("test/files/sharedStrings.xml")

    strings = Xsv::SharedStringsParser.parse(@file)

    assert_includes strings, "This sharedString is split down the middle"
    refute_includes strings, ""
    refute_includes strings, nil

    assert_equal 33, strings.length
  end

  def test_whitespace
    @file = File.open("test/files/sharedStrings-whitespace.xml")

    strings = Xsv::SharedStringsParser.parse(@file)

    assert_includes strings, "A       B"
    assert_includes strings, "   Leading"
    assert_includes strings, "Trailing      "
  end

  def test_phonetic
    @file = File.open("test/files/phonetic.xml")

    strings = Xsv::SharedStringsParser.parse(@file)
    assert_equal ["Some strings"], strings
  end
end
