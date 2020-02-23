require "test_helper"

class SharedStringsParserTest < Minitest::Test
  def setup
    @file = File.open("test/files/sharedStrings.xml")
  end

  def test_parser
    strings = []

    strings = Xsv::SharedStringsParser.parse(@file)

    assert_includes strings, "This sharedString is split down the middle"
    refute_includes strings, ""
    refute_includes strings, nil

    assert_equal 33, strings.length
  end
end
