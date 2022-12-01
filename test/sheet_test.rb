require "./test/test_helper"

class SheetTest < Minitest::Test
  # Note: Many tests for the sheet class live in the test cases for various file formats

  def test_enumerable
    @workbook = Xsv.open("test/files/excel2016.xlsx")

    first_row = @workbook.sheets[0].first
    assert_equal @workbook.sheets[0][0], first_row

    filtered_rows = @workbook.sheets[0].select { |r| r[1].to_i > 2 }
    assert_equal 2, filtered_rows.length
  end

  def test_empty
    @workbook = Xsv.open("test/files/empty.xlsx")
    sheet = @workbook.sheets[0]
    sheet.parse_headers!

    assert_equal([], sheet.headers)
    assert_equal({}, sheet[0])
  end

  def test_inspect
    @workbook = Xsv.open("test/files/empty.xlsx")

    assert_match(/mode=array/, @workbook.sheets[0].inspect)
  end

  def test_open_parse_headers
    @hash_workbook = Xsv.open("test/files/excel2016.xlsx", parse_headers: true)
    assert_kind_of Hash, @hash_workbook.sheets[0][0]

    @array_workbook = Xsv.open("test/files/excel2016.xlsx", parse_headers: false)
    assert_kind_of Array, @array_workbook.sheets[0][0]
  end

  def test_duplicate_headers
    @sheet = Xsv.open("test/files/dupe-headers.xlsx").sheets[0]

    error = assert_raises Xsv::DuplicateHeaders do
      @sheet.parse_headers!
    end

    assert_equal error.message, "Duplicate header 'Header BD' found, consider parsing this sheet in array mode."

    # Ensure array mode didn't break in the process
    assert_equal :array, @sheet.mode
    assert_equal ["Header A", "Header BD", "Header C", "Header BD", "Header E"], @sheet.first
  end

  def test_duplicate_headers_on_open
    error = assert_raises Xsv::DuplicateHeaders do
      Xsv.open("test/files/dupe-headers.xlsx", parse_headers: true)
    end

    assert_equal error.message, "Duplicate header 'Header BD' found, consider parsing this sheet in array mode."
  end
end
