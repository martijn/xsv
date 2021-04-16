require "./test/test_helper"

class HelpersTest < Minitest::Test
  include Xsv::Helpers

  def test_parse_number_integer
    assert_equal 1, parse_number("1")
  end

  def test_parse_number_float
    assert_equal 0.1, parse_number("0.1")
  end

  def test_parse_number_complex
    assert_equal 0.001, parse_number("1E-3")
  end
end
