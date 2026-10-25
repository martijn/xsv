require "./test/test_helper"

class ErrorValuesTest < Minitest::Test
  # errors.xml has the errors of formulas as Excel writes them, and an error cell without a value
  def test_error_values
    workbook = Xsv.open("test/files/excel2016.xlsx")
    rows = []
    Xsv::SheetRowsHandler.new(:array, nil, [nil] * 6, workbook, 0, 99) { |row| rows << row }
      .parse(File.read("test/files/errors.xml"))

    assert_equal [["#N/A", "#DIV/0!", "#REF!", "#NAME?", "#VALUE!", nil]], rows
  end
end
