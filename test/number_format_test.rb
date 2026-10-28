require "./test/test_helper"

class NumberFormatTest < Minitest::Test
  include Xsv::Helpers

  # number-format-text.xlsx was written by openpyxl, with numbers in formats with literal text: 7.5 in 0.0 "hrs",
  # 1200 in #,##0 "per month", 3 in 0 "days", 2.5 in [Red]0.00;[Red]-0.00, 4.25 in 0.00 "mins", and the time 12:00
  # in h:mm "h"
  def test_literal_text
    row = Xsv.open("test/files/number-format-text.xlsx").sheets[0][0]

    assert_equal [7.5, 1200, 3, 2.5, 4.25, "12:00"], row
  end

  def test_number_format_kind
    assert_nil number_format_kind('0.0 "hrs"')
    assert_nil number_format_kind('#,##0 "per month"')
    assert_nil number_format_kind("[Red]0.00;[Red]-0.00")
    assert_nil number_format_kind('_("€"\ * #,##0.00_);_("€"\ * \(#,##0.00\);_("€"\ * "-"??_);_(@_)')
    assert_equal :date, number_format_kind('yyyy"年"m"月"d"日"')
    assert_equal :time, number_format_kind('"上午/下午 "hh"時"mm"分"ss"秒 "')
    assert_equal :time, number_format_kind('[$-F400]h:mm:ss\ AM/PM')
    assert_equal :datetime, number_format_kind('yyyy-mm-dd "at" h:mm')
  end

  # Each of these was taken for a different kind of format before
  def test_number_format_kind_changes
    assert_nil number_format_kind('0.0\ \h\r\s')
    assert_nil number_format_kind('0\ \d\a\y\s')
    assert_nil number_format_kind('@" sheets"')
    assert_equal :date, number_format_kind('[$-x-sysdate]dddd\,\ mmmm\ dd\,\ yyyy')
    assert_equal :time, number_format_kind("[Red][<=100]h:mm;[Blue]0")
    assert_equal :time, number_format_kind("h:mm am/pm")
    assert_equal :time, number_format_kind("h:mm:ss a/p")
  end

  # The elapsed time codes in brackets, such as [mm], are codes rather than literal text. Not asserted as :time,
  # since a PR that reads elapsed times returns :elapsed_time for them.
  def test_number_format_kind_elapsed_time
    refute_nil number_format_kind("[mm]:ss")
  end
end
