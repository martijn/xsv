require "test_helper"

class WorkbookTest < Minitest::Test
  def test_open_filename
    @workbook = Xsv::Workbook.open("test/files/office365-xl7.xlsx")

    refute_empty @workbook.sheets
  end

  def test_open_buffer
    file = File.open("test/files/office365-xl7.xlsx")

    @workbook = Xsv::Workbook.open(file)

    refute_empty @workbook.sheets
  end

  def test_open_string
    string = File.read("test/files/office365-xl7.xlsx")

    @workbook = Xsv::Workbook.open(string)

    refute_empty @workbook.sheets
  end

  def test_open_tempfile
    t = Tempfile.new
    t.write(File.read("test/files/office365-xl7.xlsx"))
    t.rewind

    @workbook = Xsv::Workbook.open(t)

    refute_empty @workbook.sheets
  end

  def test_open_nonexisting
    assert_raises Zip::Error do
      @workbook = Xsv::Workbook.open("does-not-exist.xlsx")
    end
  end

  def test_close
    @workbook = Xsv::Workbook.open("test/files/office365-xl7.xlsx")

    @workbook.close
    assert_nil @workbook.sheets
  end
end
