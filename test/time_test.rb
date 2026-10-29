require "./test/test_helper"

class TimeTest < Minitest::Test
  include Xsv::Helpers

  # time-seconds.xlsx was written by openpyxl, with the times 09:30:15, 09:30:45, 15:25 and 09:30:15.250
  def test_seconds
    row = Xsv.open("test/files/time-seconds.xlsx").sheets[0][0]

    assert_equal ["09:30:15", "09:30:45", "15:25", "09:30:15.250"], row
  end

  def test_parse_time_rounds_to_the_millisecond
    assert_equal "09:30:15", parse_time(0.396006944)
    assert_equal "15:25", parse_time(46188.6423611111)
    assert_equal "23:59:59.999", parse_time(0.99999999)
  end

  # A time that rounds up to a whole day is midnight, as Excel shows it, rather than "24:00"
  def test_parse_time_midnight
    assert_equal "00:00", parse_time(0.999999999999)
    assert_equal "00:00", parse_time(46188.99999999999)
  end

  # Excel shows a negative time in the 1904 date system
  def test_parse_time_negative
    assert_equal "-01:30", parse_time(-0.0625)
    assert_equal "-06:00:15", parse_time(-(6 * 3600 + 15) / 86_400.0)
  end
end
