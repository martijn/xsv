require "test_helper"

class Excel2016Test < Minitest::Test
  def setup
    @file = Xsv::File.new("test/files/excel2016.xlsx")
  end

  def test_access_sheets_by_index
    refute_equal @file.sheets[0], @file.sheets[1]
    assert_nil @file.sheets[3]
  end

  def test_access_row_by_index
    assert_kind_of Array, @file.sheets[0][0]
  end

  def test_value_types
    row = @file.sheets[0][1]

    assert_equal row[0], "Foo"
    assert_equal row[1], 2
    assert_nil row[2]
    assert_equal row[3], Date.new(2020, 2, 20)
    skip do
      # TODO issue #3
      assert_equal row[4], "10:00"
    end
    assert_equal row[5], 4
  end

  def test_fetch_all_columns
    @file.sheets[1][0].length == 4
  end

  def test_fetch_all_rows
    rows = 0
    @file.sheets[1].each_row do |row|
      rows += 1
    end

    assert_equal rows, 3
  end
end
