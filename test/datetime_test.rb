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

  # datetime-dst.xlsx was written by openpyxl, with 09:30:15 on the days in 2026 when daylight saving time starts
  # and ends in the United States
  def test_daylight_saving_time
    with_time_zone("America/New_York") do
      row = Xsv.open("test/files/datetime-dst.xlsx").sheets[0][0]

      assert_equal [Time.new(2026, 3, 8, 9, 30, 15), Time.new(2026, 11, 1, 9, 30, 15)], row
    end
  end

  private

  def with_time_zone(zone)
    previous = ENV["TZ"]
    ENV["TZ"] = zone
    skip "Time zone #{zone} is not available" if Time.new(2026, 3, 8).utc_offset == Time.new(2026, 3, 9).utc_offset

    yield
  ensure
    ENV["TZ"] = previous
  end
end
