#!/usr/bin/env ruby

require "bundler/inline"

gemfile do
  source "https://rubygems.org"

  gemspec
  gem "benchmark-memory"
  gem "benchmark-perf"
end

require "stringio"
require "tmpdir"

# Parser without callback logic, to measure the XML parser in isolation
class NullParser < Xsv::SaxParser
  def start_element(name, attrs)
  end

  def end_element(name)
  end

  def characters(value)
  end
end

# Generates a workbook with mostly non-ASCII text, using shared strings, inline strings and entities
def generate_utf8_workbook(path, rows: 20_000)
  words = %w[Zürich café naïve Ελληνικά 日本語テキスト Ñandú € 😀emoji Straße größer плохо]
  shared_strings = Array.new(5000) { |i| "#{words[i % words.size]} #{i} &amp; #{words[(i * 7) % words.size]}" }

  sheet = +%(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n)
  sheet << %(<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><dimension ref="A1:F#{rows}"/><sheetData>)
  rows.times do |r|
    n = r + 1
    sheet << %(<row r="#{n}" spans="1:6">)
    sheet << %(<c r="A#{n}" t="s"><v>#{r % shared_strings.size}</v></c>)
    sheet << %(<c r="B#{n}" t="inlineStr"><is><t>#{words[r % words.size]} — row #{n} &amp; more</t></is></c>)
    sheet << %(<c r="C#{n}"><v>#{r * 3.25}</v></c>)
    sheet << %(<c r="D#{n}" s="1"><v>#{40000 + r % 1000}</v></c>)
    sheet << %(<c r="E#{n}" t="str"><v>Ünïcödé #{n}</v></c>)
    sheet << %(<c r="F#{n}" t="b"><v>#{r % 2}</v></c>)
    sheet << "</row>"
  end
  sheet << "</sheetData></worksheet>"

  ns = "http://schemas.openxmlformats.org"
  files = {
    "[Content_Types].xml" => %(<?xml version="1.0" encoding="UTF-8"?><Types xmlns="#{ns}/package/2006/content-types"><Default Extension="xml" ContentType="application/xml"/></Types>),
    "xl/workbook.xml" => %(<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="#{ns}/spreadsheetml/2006/main" xmlns:r="#{ns}/officeDocument/2006/relationships"><sheets><sheet name="Ünïcödé" sheetId="1" r:id="rId1"/></sheets></workbook>),
    "xl/_rels/workbook.xml.rels" => %(<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="#{ns}/package/2006/relationships"><Relationship Id="rId1" Type="#{ns}/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>),
    "xl/styles.xml" => %(<?xml version="1.0" encoding="UTF-8"?><styleSheet xmlns="#{ns}/spreadsheetml/2006/main"><cellXfs count="2"><xf numFmtId="0"/><xf numFmtId="14" applyNumberFormat="1"/></cellXfs></styleSheet>),
    "xl/sharedStrings.xml" => %(<?xml version="1.0" encoding="UTF-8"?><sst xmlns="#{ns}/spreadsheetml/2006/main" count="#{shared_strings.size}" uniqueCount="#{shared_strings.size}">#{shared_strings.map { |s| "<si><t>#{s}</t></si>" }.join}</sst>),
    "xl/worksheets/sheet1.xml" => sheet
  }

  Zip::OutputStream.open(path) do |zip|
    files.each do |name, content|
      zip.put_next_entry(name)
      zip.write(content)
    end
  end
end

def iterate(sheet)
  sheet.each do |row|
    row.each do |cell|
    end
  end
end

def bench(label, &block)
  perf = Benchmark::Perf.cpu(repeat: 5, &block)
  memory = Benchmark.memory(quiet: true) { |bm| bm.report(&block) }.entries.first.measurement

  printf "%-16s %8.1fms avg %5.1fms stdev %9d objects %7.1f MB allocated\n", label,
    perf.avg * 1000, perf.stdev * 1000, memory.objects.allocated, memory.memory.allocated / 1_000_000.0
end

def bench_workbook(path)
  sheet_xml = Zip::File.open(path) { |zip| zip.read("xl/worksheets/sheet1.xml") }

  bench("parse XML only") { NullParser.new.parse(StringIO.new(sheet_xml)) }
  bench("open workbook") { Xsv.open(path) }

  sheet = Xsv.open(path).sheets[0]
  bench("array mode") { iterate(sheet) }

  sheet.parse_headers!
  bench("hash mode") { iterate(sheet) }
end

puts RUBY_DESCRIPTION

puts "\n--- 10K ROWS, ASCII (test/files/10k-sheet.xlsx) ---"
bench_workbook("test/files/10k-sheet.xlsx")

Dir.mktmpdir do |dir|
  path = File.join(dir, "utf8.xlsx")
  generate_utf8_workbook(path)

  puts "\n--- 20K ROWS, UTF-8 (generated) ---"
  bench_workbook(path)
end
