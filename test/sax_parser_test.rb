require "./test/test_helper"

class SaxParserTest < Minitest::Test
  def test_truncated_document
    str = File.open("test/files/sheet1.xml") { |file| file.read(100) }

    parser = Class.new(Xsv::SaxParser) do
      def start_element(_, _)
      end
    end

    assert_raises Xsv::Error do
      parser.new.parse(str)
    end
  end

  def test_incomplete_utf8_tail_size
    # Complete ASCII
    assert_equal 0, Xsv::SaxParser.incomplete_utf8_tail_size("hello".b)

    # Complete 2-byte UTF-8 (ñ = C3 B1)
    assert_equal 0, Xsv::SaxParser.incomplete_utf8_tail_size("cañon".b)

    # Incomplete 2-byte UTF-8 (just the leading byte C3)
    assert_equal 1, Xsv::SaxParser.incomplete_utf8_tail_size("ca\xC3".b)

    # Complete 3-byte UTF-8 (€ = E2 82 AC)
    assert_equal 0, Xsv::SaxParser.incomplete_utf8_tail_size("100\xE2\x82\xAC".b)

    # Incomplete 3-byte UTF-8 (just E2)
    assert_equal 1, Xsv::SaxParser.incomplete_utf8_tail_size("100\xE2".b)

    # Incomplete 3-byte UTF-8 (E2 82, missing last byte)
    assert_equal 2, Xsv::SaxParser.incomplete_utf8_tail_size("100\xE2\x82".b)

    # Complete 4-byte UTF-8 (😀 = F0 9F 98 80)
    assert_equal 0, Xsv::SaxParser.incomplete_utf8_tail_size("hi\xF0\x9F\x98\x80".b)

    # Incomplete 4-byte UTF-8 (just F0)
    assert_equal 1, Xsv::SaxParser.incomplete_utf8_tail_size("hi\xF0".b)

    # Incomplete 4-byte UTF-8 (F0 9F)
    assert_equal 2, Xsv::SaxParser.incomplete_utf8_tail_size("hi\xF0\x9F".b)

    # Incomplete 4-byte UTF-8 (F0 9F 98)
    assert_equal 3, Xsv::SaxParser.incomplete_utf8_tail_size("hi\xF0\x9F\x98".b)

    # Empty string
    assert_equal 0, Xsv::SaxParser.incomplete_utf8_tail_size("".b)
  end

  # Mock IO that yields chunks at specific byte boundaries to test UTF-8 handling
  class ChunkedIO
    def initialize(chunks)
      @chunks = chunks
      @index = 0
    end

    def sysread(_size)
      raise EOFError if @index >= @chunks.length

      chunk = @chunks[@index]
      @index += 1
      chunk
    end
  end

  def test_utf8_split_across_chunks
    # XML with a 3-byte UTF-8 character (€ = E2 82 AC) split across chunks
    # Split the XML so the euro sign in the attribute is broken: "100" + E2 | 82 AC + "\">"
    chunk1 = "<root attr=\"100\xE2"
    chunk2 = "\x82\xAC\">€50</root>"

    collected_attrs = []
    collected_chars = []

    parser = Class.new(Xsv::SaxParser) do
      define_method(:start_element) do |name, attrs|
        collected_attrs << [name, attrs&.dup]
      end

      define_method(:characters) do |chars|
        collected_chars << chars
      end

      define_method(:end_element) do |name|
      end
    end

    io = ChunkedIO.new([chunk1, chunk2])
    parser.new.parse(io)

    assert_equal [["root", {attr: "100€"}]], collected_attrs
    assert_equal ["€50"], collected_chars
  end

  def test_utf8_4byte_split_across_chunks
    # XML with a 4-byte UTF-8 character (😀 = F0 9F 98 80) split across chunks
    chunk1 = "<t>\xF0\x9F"  # Start of emoji
    chunk2 = "\x98\x80</t>" # End of emoji

    collected_chars = []

    parser = Class.new(Xsv::SaxParser) do
      define_method(:start_element) do |name, attrs|
      end

      define_method(:characters) do |chars|
        collected_chars << chars
      end

      define_method(:end_element) do |name|
      end
    end

    io = ChunkedIO.new([chunk1, chunk2])
    parser.new.parse(io)

    assert_equal ["😀"], collected_chars
  end
end
