require "./test/test_helper"

# A character that cannot be written in XML is escaped as _xHHHH_, such as _x000D_ for a carriage return
class EscapedCharactersTest < Minitest::Test
  include Xsv::Helpers

  def test_shared_strings
    strings = Xsv::SharedStringsParser.parse(File.open("test/files/sharedStrings-escaped.xml"))

    # Each t element is escaped on its own, so text that looks like an escape across two runs is not one
    assert_equal ["Line 1\r\nLine 2", "Bell\a", "_x000D_ is a carriage return", "Rich\r\ntext", "_x000D_ in two runs"],
      strings
  end

  def test_shared_strings_with_invalid_utf8
    strings = Xsv::SharedStringsParser.parse("<sst><si><t>bad \xC3 _x000D_</t></si></sst>".b)

    assert_equal ["bad \xC3 _x000D_".b.force_encoding(Encoding::UTF_8)], strings
  end

  def test_inline_and_formula_strings
    workbook = Xsv.open("test/files/excel2016.xlsx")
    rows = []
    Xsv::SheetRowsHandler.new(:array, nil, [nil] * 4, workbook, 0, 99) { |row| rows << row }
      .parse(File.read("test/files/escaped-characters.xml"))

    assert_equal [["Line 1\r\nLine 2", "Bell\a", "Smile 😀 and _x000D_", "_x000D_ in two runs"]], rows
  end

  def test_unescape_characters
    assert_equal "a\rb", unescape_characters("a_x000D_b")
    assert_equal "a_x000D_b", unescape_characters("a_x005F_x000D_b")
    assert_equal "_\r", unescape_characters("_x005F__x000D_")
    assert_equal "😀", unescape_characters("_xD83D__xDE00_")
    assert_equal "😀", unescape_characters("_xd83d__xde00_")
    assert_equal "_x00_ and _xGHIJ_", unescape_characters("_x00_ and _xGHIJ_")
  end

  # A surrogate without the other half of its pair is left as it is, but the escapes around it are not
  def test_unescape_characters_lone_surrogate
    assert_equal "_xD83D_", unescape_characters("_xD83D_")
    assert_equal "\r_xD83D_", unescape_characters("_x000D__xD83D_")
    assert_equal "😀_xD83D_", unescape_characters("_xD83D__xDE00__xD83D_")
    assert_equal "_xDE00_\r", unescape_characters("_xDE00__x000D_")
  end
end
