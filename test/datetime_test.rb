require "./test/test_helper"

class DatetimeTest < Minitest::Test
  include Xsv::Helpers

  # datetime-seconds.xlsx was written by openpyxl, with the times 09:30:15, 09:30:15.250, 23:59:59.999 and 09:30
  def test_seconds
    row = Xsv.open("test/files/datetime-seconds.xlsx").sheets[0][0]

    assert_equal [
      Time.new(2026, 6, 15, 9, 30, 15),
      Time.new(2026, 6, 15, 9, 30, Rational(15_250, 1000)),
      Time.new(2026, 6, 15, 23, 59, Rational(59_999, 1000)),
      Time.new(2026, 6, 15, 9, 30)
    ], row
  end

  def test_parse_datetime_rounds_to_the_millisecond
    assert_equal Time.new(2026, 6, 15, 9, 30, 15), parse_datetime(46188.396006944)
    # A time just before midnight stays on its day, where rounding to the minute moved it to the next day
    assert_equal Time.new(2026, 6, 15, 23, 59, Rational(59_991, 1000)), parse_datetime(46188.9999999)
    # A time that rounds up to midnight is on the next day
    assert_equal Time.new(2026, 6, 16), parse_datetime(46188.99999999999)
  end
end
