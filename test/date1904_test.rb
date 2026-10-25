require "./test/test_helper"

class Date1904Test < Minitest::Test
  # date1904.xlsx was written by openpyxl in the 1904 date system, with the date 2026-06-15 and the date and time
  # 2026-06-15 09:30
  def test_1904_date_system
    workbook = Xsv.open("test/files/date1904.xlsx")

    assert_equal Xsv::Helpers::EPOCH_1904, workbook.epoch
    assert_equal [Date.new(2026, 6, 15), Time.new(2026, 6, 15, 9, 30)], workbook.sheets[0][0]
  end

  # caxlsx.xlsx says that it does not use the 1904 date system, with date1904="false"
  def test_1900_date_system
    assert_equal Xsv::Helpers::EPOCH, Xsv.open("test/files/caxlsx.xlsx").epoch
    assert_equal Xsv::Helpers::EPOCH, Xsv.open("test/files/excel2016.xlsx").epoch
  end

  def test_workbook_properties
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><workbookPr date1904="true" defaultThemeVersion="166925"/></workbook>
    XML

    assert_equal "true", Xsv::WorkbookPropertiesHandler.get_properties(xml)[:date1904]
  end
end
