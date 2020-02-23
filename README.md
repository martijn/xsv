# Xsv .xlsx reader

Xsv is a very basic parser for Office Open XML spreadsheet files (.xlsx files)
that aims to provide feature parity with common CSV readers with high
performance. This means it only parses values to basic Ruby types and does not
deal with most formatting or more advanced functionality. The goal is to allow
for fast parsing of large worksheets with minimal RAM and CPU consumption.

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

## Usage

Xsv has two modes of operation. By default it returns an array for
each row in the sheet:

```ruby
x = Xsv::Workbook.open("sheet.xlsx")

sheet = x.sheets[0]

# Iterate over rows
sheet.each_row do |row|
  row # => ["header1", "header2"], etc.
end

# Access row by index (zero-based)
sheet[1] # => ["value1", "value2"]
```

Alternatively, it can load the headers from the first row and return a hash
for every row:

```ruby
x = Xsv::Workbook.open("sheet.xlsx")

sheet = x.sheets[0]

sheet.mode # => :array

# Parse headers and switch to hash mode
sheet.parse_headers!

sheet.mode # => :hash

sheet.each_row do |row|
  row # => {"header1" => "value1", "header2" => "value2"}, etc.
end

sheet[1] # => {"header1" => "value1", "header2" => "value2"}
```

Be aware that hash mode will lead to unpredictable results if you have multiple
columns with the same name!

`Xsv::Workbook.open` accepts a filename, or a IO or String containing a workbook.

`Xsv::Sheet` implements `Enumerable` so you can call methods like `#first`,
`#filter` and `#map` on it.

### Assumptions

Since Xsv treats worksheets like csv files it makes certain assumptions about your
sheet:

- In array mode, your data starts on the first row

- In has mode the first row of the sheet contains headers, followed by rows of data

If your data or headers does not start on the first row of the sheet you can
tell Xsv to skip a number of rows:

```ruby
workbook.sheets[0].row_skip = 1
```

All operations will honour this offset, making the skipped rows unreachable.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/martijn/xsv.
Please provide an .xlsx file with a minimum breaking example that is acceptable
for inclusion in the source code repository.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
