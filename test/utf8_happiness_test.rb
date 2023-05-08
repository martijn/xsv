require "./test/test_helper"

class Utf8HappinessTest < Minitest::Test
  def test_utf8_sheet_names
    workbook = Xsv.open("test/files/utf8-sheetnames.xlsx")

    assert_equal "ÄËÏÖÜàèìòùâêîôû", workbook.sheets[0].name
    assert_equal " ¯＼(ツ)／¯ ", workbook.sheets[1].name
    assert_equal "☼♔∞♛☆", workbook.sheets[2].name

    assert_same Encoding::UTF_8, workbook.sheets[0].name.encoding

    assert_same workbook.sheets[2], workbook.sheets_by_name("☼♔∞♛☆").first
  end

  def test_utf8_and_entities
    sheet = Xsv.open("test/files/utf8.xlsx").sheets[0]

    assert_equal Encoding::UTF_8, sheet[0][0].encoding
    assert_equal "Zé", sheet[0][0]
    assert_equal %q(entities "&'<>ä), sheet[1][0]
    assert_equal "euro €", sheet[5][0]
  end
end
