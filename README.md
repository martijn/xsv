# Xsv .xlsx reader

[![Travis CI](https://img.shields.io/travis/martijn/xsv/master)](https://travis-ci.org/martijn/xsv)
[![Codecov](https://img.shields.io/codecov/c/github/martijn/xsv/main)](https://app.codecov.io/gh/martijn/xsv)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](https://rubydoc.info/github/martijn/xsv)
[![Gem Version](https://badge.fury.io/rb/xsv.svg)](https://badge.fury.io/rb/xsv)

Xsv is a fast, lightweight, pure Ruby parser for ISO/IEC 29500 Office Open XML spreadsheet files
(commonly known as Excel or .xlsx files). It strives to be minimal in the
sense that it provides nothing a CSV reader wouldn't, meaning it only
deals with minimal formatting and cannot create or modify documents.

Xsv is designed for worksheets with a single table of data, optionally
with a header row. It only casts values to basic Ruby types (integer, float,
date and time) and does not deal with most formatting or more advanced
functionality. It strives for fast processing of large worksheets with
minimal RAM and CPU consumption and has been in production use since the earliest
versions.

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

Xsv targets ruby >= 2.5 and has a just single dependency, `rubyzip`. It has been
tested successfully with MRI, JRuby, and TruffleRuby. Due to the lack of
native extensions should work well in multi-threaded environments or in Ractor
when that becomes stable.

## Usage

Xsv has two modes of operation. By default, it returns an array for
each row in the sheet:

```ruby
x = Xsv.open("sheet.xlsx") # => #<Xsv::Workbook sheets=1>

sheet = x.sheets[0]

# Iterate over rows
sheet.each_row do |row|
  row # => ["header1", "header2"], etc.
end

# Access row by index (zero-based)
sheet[1] # => ["value1", "value2"]
```

Alternatively, it can load the headers from the first row and return a hash
for every row by calling `parse_headers!` on th sheet or setting the `default_mode`
option:

```ruby
x = Xsv.open("sheet.xlsx")

sheet = x.sheets[0]

sheet.mode # => :array

# Parse headers and switch to hash mode

sheet.parse_headers!

sheet.mode # => :hash

sheet.each_row do |row|
  row # => {"header1" => "value1", "header2" => "value2"}, etc.
end

sheet[1] # => {"header1" => "value1", "header2" => "value2"}

# Parse headers for all sheets on open

x = Xsv.open("sheet.xlsx", default_mode: :hash)

x.sheets[0].mode # => :hash
x.sheets[0][1]   # => {"header1" => "value1", "header2" => "value2"}
```

Be aware that hash mode will lead to unpredictable results if the worksheet
has multiple columns with the same header.

`Xsv.open` accepts a filename, or an IO or String containing a workbook. Optionally, you can pass a block
which will be called with the workbook as parameter, like `File#open`. Prior to Xsv 1.1.0, `Xsv.open`
was used to open workbooks. The parameters are identical.

`Xsv::Sheet` implements `Enumerable` so you can call methods like `#first`,
`#filter`/`#select`, and `#map` on it.

The sheets can be accessed by index or by name:

```ruby
x = Xsv.open("sheet.xlsx")

sheet = x.sheets[0] # gets sheet by index

sheet = x.sheets_by_name('Name').first # gets sheet by name
```

To get all the sheets names:

```ruby
sheet_names = x.sheets.map(&:name)
```

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

Pre-1.0, Xsv used a native extension for XML parsing, which was faster than the native Ruby one (on MRI). But even with the native Ruby version generally Xsv still outperforms other Ruby parsing gems.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/martijn/xsv.
Please provide an .xlsx file with a minimum breaking example that is acceptable
for inclusion in the source code repository.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
