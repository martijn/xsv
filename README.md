# Xsv .xlsx reader

Xsv is a very basic parser for Excel files in the .xlsx format that strives to
provide feature parity with common CSV readers and nothing more. This should
allow for fast parsing of large worksheets with minimal RAM and CPU consumption.

Xsv stands for 'Excel Separated Values' because Excel just gets in the way.

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

```ruby
x = Xsv::File.new("sheet.xlsx")

x.sheets[0].each_row(read_headers: true) do |row|
  row # => { "header1" => "value1", "header2", "value2" }
end
j
x.sheets[0].each_row do |row|
  row # => ["header1", "header2"]
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/xsv.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
