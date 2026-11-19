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

  def test_parse_number_lowercase_exponent
    assert_equal 0.00002, parse_number("2e-05")
    assert_equal 1e20, parse_number("1e+20")
  end
end
