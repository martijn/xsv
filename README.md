# Xsv .xlsx reader for Ruby

[![Test badge](https://img.shields.io/github/actions/workflow/status/martijn/xsv/ruby.yml?branch=main)](https://github.com/martijn/xsv/actions/workflows/ruby.yml)
[![Yard Docs badge](http://img.shields.io/badge/yard-docs-blue.svg)](https://rubydoc.info/github/martijn/xsv)
[![Gem Version badge](https://badge.fury.io/rb/xsv.svg)](https://badge.fury.io/rb/xsv)

Xsv is a high performance, lightweight, pure Ruby parser for ISO/IEC 29500 Office Open XML spreadsheets
(commonly known as Excel or .xlsx files). It strives to be minimal in the sense that it provides nothing a
CSV reader wouldn't. This means it only deals with the minimal required formatting and cannot create or modify documents.
Xsv can handle very large Excel files with minimal resources thanks to a custom streaming XML parser that
is optimized for the Excel file format.

Xsv is designed for worksheets with a single table of data, optionally
with a header row. It only casts values to basic Ruby types (integer, float,
date and time) and does not deal with most formatting or more advanced
functionality. Xsv has been production-ready since the initial release.

Xsv stands for 'Excel Separated Values', because Excel just gets in the way.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'xsv'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install xsv

Xsv targets ruby >= 2.7 and has a just single dependency, `rubyzip`. It has been
tested successfully with MRI, JRuby, and TruffleRuby. It has no native extensions
and is designed to be thread-safe.

## Usage

### Array and hash mode

Xsv has two modes of operation. By default, it returns an array for
each row in the sheet:

```ruby
workbook = Xsv.open("sheet.xlsx") # => #<Xsv::Workbook sheets=1>

# Access worksheet by index, 0 is the first sheet
sheet = workbook[0]
# or, access worksheet by name
sheet = workbook["Sheet1"]

# Iterate over rows
sheet.each do |row|
  row # => ["header1", "header2"]
end

# Access row by index (zero-based)
sheet[1] # => ["value1", "value2"]
```

Alternatively, it can load the headers from the first row and return a hash
for every row by calling `parse_headers!` on the sheet or setting the `parse_headers`
option on open:

```ruby
# Parse headers for all sheets on open

workbook = Xsv.open("sheet.xlsx", parse_headers: true)

# Get the first row from the first sheet
workbook.first.first   # => {"header1" => "value1", "header2" => "value2"}

# Manually parse headers for a single sheet

workbook = Xsv.open("sheet.xlsx")

sheet = workbook[0]

sheet[0]  # => ["header1", "header2"]

sheet.parse_headers!

sheet[0] # => {"header1" => "value1", "header2" => "value2"}
```

Xsv will raise `Xsv::DuplicateHeaders` if it detects duplicate values in the header row when calling
`#parse_headers!` or when opening a workbook with `parse_headers: true` to ensure hash keys are unique.

`Xsv::Sheet` implements `Enumerable` so along with `#each`
you can call methods like `#first`, `#filter`/`#select`, and `#map` on it. Likewise these methods can
be used on `Xsv::Workbook` to iterate over sheets, for example:

```ruby
# Get the name of all the sheets in a workbook
sheet_names = @workbook.map(&:name)
```

### Opening a string or buffer instead of filename

`Xsv.open` accepts a filename, or an IO or String containing a workbook. Optionally, you can pass a block
which will be called with the workbook as parameter, like `File#open`. Example of this together:

```ruby
# Use an existing IO-like object as source

file = File.open("sheet.xlsx")

Xsv.open(file) do |workbook|
  puts workbook.inspect
end

# or even:

Xsv.open(file.read) do |workbook|
  puts workbook.inspect
end
```

Prior to Xsv 1.1.0, `Xsv::Workbook.open` was used instead of `Xsv.open`. The parameters are identical and
the former is maintained for backwards compatibility.

### Assumptions

Since Xsv treats worksheets like csv files it makes certain assumptions about your
sheet:

- In array mode, your data starts on the first row

- In hash mode the first row of the sheet contains headers, followed by rows of data

If your data or headers do not start on the first row of the sheet you can
tell Xsv to skip a number of rows:

```ruby
workbook.sheets[0].row_skip = 1
```

All operations will honour this offset, making the skipped rows unreachable.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Performance and Benchmarks

Xsv is faster and more memory efficient than other gems because of two things: it only _reads values_ from Excel files and it's based on a SAX-based parser instead of a DOM-based parser. If you want to read some background on this, check out my blog post on
[Efficient XML parsing in Ruby](https://storck.io/posts/efficient-xml-parsing-in-ruby/).

Jamie Schembri did a shootout of Xsv against various other Excel reading gems comparing parsing speed, memory usage, and allocations.
Check our his blog post: [Faster Excel parsing in Ruby](https://blog.schembri.me/post/faster-excel-parsing-in-ruby/).

Pre-1.0, Xsv used a native extension for XML parsing, which was faster than the native Ruby one (on MRI). But even with the native Ruby version generally Xsv still outperforms the competition.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/martijn/xsv.
Please provide an .xlsx file with a minimum breaking example that is acceptable
for inclusion in the source code repository.

## License

Copyright © Martijn Storck and Xsv contributors

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
