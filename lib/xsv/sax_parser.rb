# frozen_string_literal: true

require "cgi"

module Xsv
  class SaxParser
    ATTR_REGEX = /((\p{Alnum}+)="(.*?)")/m

    # Returns the number of bytes to trim from the end of a UTF-8 string
    # to avoid splitting a multi-byte character. Returns 0 if the string
    # ends with a complete character.
    def self.incomplete_utf8_tail_size(bytes)
      return 0 if bytes.empty?

      # Check up to 3 bytes from the end (max UTF-8 char is 4 bytes)
      check_length = [bytes.bytesize, 3].min
      tail = bytes.byteslice(-check_length, check_length)

      tail.each_byte.with_index.reverse_each do |byte, i|
        # Check if this is a leading byte (starts a multi-byte sequence)
        if byte >= 0xC0 # 11000000 - start of multi-byte sequence
          # i is position in tail, bytes after leading byte = check_length - i - 1
          # total bytes in sequence = 1 (leading) + continuation bytes = check_length - i
          bytes_in_sequence = check_length - i

          # Determine expected length from leading byte
          expected_length = if byte >= 0xF0 # 11110xxx - 4 byte sequence
            4
          elsif byte >= 0xE0 # 1110xxxx - 3 byte sequence
            3
          else # 110xxxxx - 2 byte sequence
            2
          end

          # If we don't have enough bytes, this sequence is incomplete
          return bytes_in_sequence if bytes_in_sequence < expected_length

          # Sequence is complete
          return 0
        elsif byte < 0x80
          # ASCII byte - string ends with complete character
          return 0
        end
        # else: continuation byte (10xxxxxx), keep looking for leading byte
      end

      0
    end

    def parse(io)
      responds_to_end_element = respond_to?(:end_element)
      responds_to_characters = respond_to?(:characters)

      state = :look_start
      if io.is_a?(String)
        pbuf = io.dup
        eof_reached = true
        must_read = false
      else
        pbuf = String.new(capacity: 8192, encoding: "utf-8")
        eof_reached = false
        must_read = true
      end
      leftover = String.new(encoding: "binary")

      loop do
        if must_read
          begin
            chunk = io.sysread(2048)
            if chunk
              # Prepend any leftover bytes from previous incomplete UTF-8 sequence
              chunk = leftover << chunk unless leftover.empty?

              # Check if chunk ends with incomplete UTF-8 sequence
              trim = SaxParser.incomplete_utf8_tail_size(chunk)
              if trim > 0
                leftover = chunk.byteslice(-trim, trim)
                chunk = chunk.byteslice(0, chunk.bytesize - trim)
              else
                leftover = String.new(encoding: "binary")
              end

              pbuf << chunk.force_encoding("utf-8")
            else
              # rubyzip < 3 returns nil from sysread on EOF
              eof_reached = true
            end
          rescue EOFError
            # EOFError is thrown by IO and rubyzip >= 3
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
              attributes = args.force_encoding("utf-8").scan(ATTR_REGEX)
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
