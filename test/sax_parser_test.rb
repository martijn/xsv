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

  # Mock IO that yields chunks at specific byte boundaries to test UTF-8 handling
  class ChunkedIO
    def initialize(chunks)
      @chunks = chunks
      @index = 0
    end

    # Splits a string into chunks of the given byte size
    def self.split(string, size)
      new(string.b.scan(/.{1,#{size}}/mn))
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

  class Recorder < Xsv::SaxParser
    attr_reader :events

    def initialize
      @events = []
    end

    def start_element(name, attrs)
      @events << [:start, name, attrs]
    end

    def end_element(name)
      @events << [:end, name]
    end

    def characters(chars)
      @events << [:chars, chars, chars.encoding]
    end
  end

  def test_any_chunk_boundary
    xml = File.read("test/files/sheet1.xml") +
      %(<x:root a="Zürich €" x:b="😀"><t>😀 Ελληνικά &amp; 日本語</t><x:t xml:space="preserve"> café </x:t><c r="A1" t="s"/><e/></x:root>)

    expected = Recorder.new.tap { |r| r.parse(xml) }.events

    (1..8).each do |size|
      assert_equal expected, Recorder.new.tap { |r| r.parse(ChunkedIO.split(xml, size)) }.events, "chunk size #{size}"
    end
  end

  def test_invalid_utf8
    xml = "<a>\x80bad</a>\xFF<b x=\"\xBF\" y=\"1\"/>".b

    events = Recorder.new.tap { |r| r.parse(xml) }.events

    assert_equal [
      [:start, "a", nil],
      [:chars, "\x80bad".b.force_encoding("utf-8"), Encoding::UTF_8],
      [:end, "a"],
      [:chars, "\xFF".b.force_encoding("utf-8"), Encoding::UTF_8],
      [:start, "b", {x: "\xBF".b.force_encoding("utf-8"), y: "1"}]
    ], events
  end
end
