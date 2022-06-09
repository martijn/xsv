require "./test/test_helper"

class SaxParserTest < Minitest::Test
  def test_truncated_document
    str = File.open("test/files/sheet1.xml") { |file| file.read(100) }

    puts str
    parser = Class.new(Xsv::SaxParser) do
      def start_element(_, _)
      end
    end

    assert_raises Xsv::Error do
      parser.new.parse(StringIO.new(str))
    end
  end
end
