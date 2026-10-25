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
  end
end
