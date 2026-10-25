require "./test/test_helper"

# Inline strings leave out the phonetic reading of their text in rPh elements, as shared strings do
class InlinePhoneticTest < Minitest::Test
  def test_inline_phonetic
    workbook = Xsv.open("test/files/excel2016.xlsx")
    rows = []
    Xsv::SheetRowsHandler.new(:array, nil, [nil] * 3, workbook, 0, 99) { |row| rows << row }
      .parse(File.read("test/files/inlineStr-phonetic.xml"))

    assert_equal [["東京", "漢字", "After"]], rows
  end
end
