# Xsv Changelog

## 0.3.18 2020-09-30

-  Improve inline string support (#18)

## 0.3.17 2020-07-03

- Fix parsing of empty worksheets (#17)

## 0.3.16 2020-06-03

- Support complex numbers (#16)

## 0.3.15 2020-06-02

- Fix issue with workbooks that don't contain shared strings (#15)

## 0.3.14 2020-05-22

- Allow opening workbooks from Tempfile and anything that responds to #read

- Preserve whitespace in text cells

## 0.3.13 2020-05-12

- Add Sheet#hidden?

- Clean up code; get rid of some deprecation warnings

## 0.3.12 - 2020-04-15

- Accessing worksheets by name (texpert)

## 0.3.11 - 2020-04-03

- Backward compatibility with Ruby 2.5 (texpert)

## 0.3.10 - 2020-03-19

- Relax version requirements for dependencies

## 0.3.9 - 2020-03-16

- Fix an edge case issue with row_skip  and empty rows

## 0.3.8 - 2020-03-11

- Improve compatibility with files exported from LibreOffice

- Support for boolean type

## 0.3.7 - 2020-03-05

Reduce retained memory, making Xsv the definite performance king among the
Ruby Excel parsing gems.

## 0.3.6 - 2020-03-05

Reduce memory usage

## 0.3.5 - 2020-03-02

Fix a Gemfile small Gemfile issue that broke the 0.3.3 and 0.3.4 releases

## 0.3.3 - 2020-03-02

Intial version with a changelog and reasonably complete YARD documentation.
