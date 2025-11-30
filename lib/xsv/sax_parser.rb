# frozen_string_literal: true

require "cgi"

module Xsv
  class SaxParser
    # Create UTF-8 regex by building from UTF-8 string pattern
    # This ensures the regex can match UTF-8 strings properly
    ATTR_PATTERN_UTF8 = "((\\p{Alnum}+)=\"(.*?)\")".encode(Encoding::UTF_8)
    ATTR_REGEX = Regexp.new(ATTR_PATTERN_UTF8, Regexp::MULTILINE)

    def parse(io)
      responds_to_end_element = respond_to?(:end_element)
      responds_to_characters = respond_to?(:characters)

      state = :look_start
      if io.is_a?(String)
        pbuf = io.dup
        eof_reached = true
        must_read = false
      else
        pbuf = String.new(capacity: 8192)
        eof_reached = false
        must_read = true
      end

      loop do
        if must_read
          begin
            pbuf << io.sysread(2048)
          rescue EOFError, TypeError
            # EOFError is thrown by IO, rubyzip returns nil from sysread on EOF
            eof_reached = true
          end

          must_read = false
        end

        if state == :look_start
          if (o = pbuf.index("<"))
            chars = pbuf.slice!(0, o + 1).chop!.force_encoding("utf-8")

            if responds_to_characters && !chars.empty?
              if chars.include?("&")
                characters(CGI.unescapeHTML(chars))
              else
                characters(chars)
              end
            end

            state = :look_end
          elsif eof_reached
            # Discard anything after the last tag in the document
            break
          else
            # Continue loop to read more data into the buffer
            must_read = true
            next
          end
        end

        if state == :look_end
          if (o = pbuf.index(">"))
            if (s = pbuf.index(" ")) && s < o
              tag_name = pbuf.slice!(0, s + 1).chop!
              args = pbuf.slice!(0, o - s)
            else
              tag_name = pbuf.slice!(0, o + 1).chop!
              args = nil
            end

            is_close_tag = tag_name.delete_prefix!("/")

            # Strip XML namespace from tag
            if (offset = tag_name.index(":"))
              tag_name.slice!(0, offset + 1)
            end

            if is_close_tag
              end_element(tag_name) if responds_to_end_element
            elsif args.nil?
              start_element(tag_name, nil)
            else
              attribute_buffer = {}
              # Convert args to UTF-8 for regex matching (rubyzip 3.x may return BINARY)
              # The content is UTF-8, so we can safely force the encoding
              args_utf8 = args.dup.force_encoding(Encoding::UTF_8)
              attributes = args_utf8.scan(ATTR_REGEX)
              while (attr = attributes.delete_at(0))
                attribute_buffer[attr[1].to_sym] = attr[2]
              end

              start_element(tag_name, attribute_buffer)

              end_element(tag_name) if responds_to_end_element && args.end_with?("/")
            end

            state = :look_start
          elsif eof_reached
            raise Xsv::Error, "Malformed XML document, looking for end of tag beyond EOF"
          else
            must_read = true
          end
        end
      end
    end
  end
end
