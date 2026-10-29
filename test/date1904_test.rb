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
    {
      '<workbookPr date1904="1"/>' => Xsv::Helpers::EPOCH_1904,
      '<workbookPr date1904="true" defaultThemeVersion="166925"/>' => Xsv::Helpers::EPOCH_1904,
      '<workbookPr date1904=" 1 "/>' => Xsv::Helpers::EPOCH_1904,
      '<workbookPr date1904="0"/>' => Xsv::Helpers::EPOCH,
      '<workbookPr date1904="false"/>' => Xsv::Helpers::EPOCH,
      "<workbookPr/>" => Xsv::Helpers::EPOCH,
      "<workbookPr></workbookPr>" => Xsv::Helpers::EPOCH,
      "" => Xsv::Helpers::EPOCH
    }.each do |workbook_pr, epoch|
      assert_equal epoch, open_with_workbook_pr(workbook_pr).epoch, workbook_pr
    end
  end

  def test_get_workbook
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><workbookPr date1904="true"/><sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>
    XML

    sheets_ids, properties = Xsv::SheetsIdsHandler.get_workbook(xml)

    assert_equal [{name: "Sheet1", sheetId: "1", id: "rId1"}], sheets_ids
    assert_equal({date1904: "true"}, properties)
  end

  private

  # Opens date1904.xlsx with its workbookPr element replaced
  def open_with_workbook_pr(workbook_pr)
    buffer = Zip::OutputStream.write_buffer do |out|
      Zip::File.open("test/files/date1904.xlsx") do |zip|
        zip.each do |entry|
          content = entry.get_input_stream.read
          content = content.sub(/<workbookPr[^>]*>/, workbook_pr) if entry.name == "xl/workbook.xml"
          out.put_next_entry(entry.name)
          out.write(content)
        end
      end
    end

    Xsv.open(buffer.string)
  end
end
