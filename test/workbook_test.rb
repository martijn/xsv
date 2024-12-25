require "./test/test_helper"

class WorkbookTest < Minitest::Test
  def test_open_filename
    @workbook = Xsv.open("test/files/office365-xl7.xlsx")

    refute_empty @workbook.sheets
  end

  def test_open_options
    @workbook = Xsv.open("test/files/office365-xl7.xlsx", trim_empty_rows: true)

    assert @workbook.trim_empty_rows
  end

  def test_open_buffer
    file = File.open("test/files/office365-xl7.xlsx")

    @workbook = Xsv.open(file)

    refute_empty @workbook.sheets
  end

  def test_open_string
    string = File.read("test/files/office365-xl7.xlsx")

    @workbook = Xsv.open(string)

    refute_empty @workbook.sheets
  end

  def test_open_tempfile
    t = Tempfile.new
    t.write(File.read("test/files/office365-xl7.xlsx"))
    t.rewind

    @workbook = Xsv.open(t)

    refute_empty @workbook.sheets
  end

  def test_legacy_open_filename
    @workbook = Xsv::Workbook.open("test/files/office365-xl7.xlsx")

    refute_empty @workbook.sheets
  end

  def test_legacy_open_options
    @workbook = Xsv::Workbook.open("test/files/office365-xl7.xlsx", trim_empty_rows: true)

    assert @workbook.trim_empty_rows
  end

  def test_legacy_open_block_syntax
    ret = Xsv::Workbook.open(File.open("test/files/office365-xl7.xlsx")) do |workbook|
      workbook.sheets.count
    end

    assert_equal 3, ret
  end

  def test_open_nonexisting
    assert_raises Zip::Error do
      @workbook = Xsv.open("does-not-exist.xlsx")
    end
  end

  def test_close
    @workbook = Xsv.open("test/files/office365-xl7.xlsx")

    @workbook.close
    assert_nil @workbook.sheets
  end

  def test_open_without_shared_strings
    @workbook = Xsv.open("test/files/no-shared-strings.xlsx")
    refute_empty @workbook.sheets
  end

  def test_new_instead_of_open
    assert_raises ArgumentError do
      Xsv::Workbook.new "not a Zip::File instance"
    end
  end

  def test_open_empty_file_from_buffer
    tempfile = Tempfile.new

    assert_raises Xsv::Error do
      @workbook = Xsv.open(tempfile)
    end
  end

  def test_open_empty_file_by_filename
    tempfile = Tempfile.new

    assert_raises Zip::Error do
      Xsv.open(tempfile.path)
    end
  end

  def test_inspect
    @workbook = Xsv.open("test/files/office365-xl7.xlsx")

    assert_match(/Xsv::Workbook/, @workbook.inspect)
  end

  def test_open_xml_sdk
    @workbook = Xsv.open("test/files/open-xml-sdk.xlsx", parse_headers: true)
    @sheet = @workbook.sheets[0]

    assert_equal "2022-03-04 12:00:00 AM", @sheet[0]["Date"]
    assert_equal "ABC123", @sheet[0]["Value"]
  end

  def test_index_open_by_index
    @workbook = Xsv.open(File.read("test/files/office365-xl7.xlsx"))

    sheet = @workbook[1]
    assert_equal "Blad2", sheet.name
  end

  def test_index_open_by_out_of_range_index
    @workbook = Xsv.open(File.read("test/files/office365-xl7.xlsx"))

    sheet = @workbook[99]
    assert_nil sheet
  end

  def test_index_open_by_name
    @workbook = Xsv.open(File.read("test/files/office365-xl7.xlsx"))

    sheet = @workbook["Blad2"]
    assert_equal "Blad2", sheet.name
  end

  def test_index_open_by_nonexistent_name
    @workbook = Xsv.open(File.read("test/files/office365-xl7.xlsx"))

    sheet = @workbook["Blad99"]
    assert_nil sheet
  end

  def test_index_open_by_invalid_type
    @workbook = Xsv.open(File.read("test/files/office365-xl7.xlsx"))

    assert_raises ArgumentError do
      @workbook[true]
    end
  end

  def test_first
    @workbook = Xsv.open(File.read("test/files/office365-xl7.xlsx"))

    assert_equal "Blad1", @workbook.first.name
  end

  def test_enumerable
    @workbook = Xsv.open(File.read("test/files/office365-xl7.xlsx"))

    assert_equal %w[Blad1 Blad2 Blad3], @workbook.map(&:name)
  end
end
