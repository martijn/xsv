# frozen_string_literal: true

module Xsv
  class SaxParser
    ATTR_REGEX = /((\S+)="(.*?)")/m

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
              if chars.index("&")
                chars.gsub!("&amp;", "&")
                chars.gsub!("&apos;", "'")
                chars.gsub!("&gt;", ">")
                chars.gsub!("&lt;", "<")
                chars.gsub!("&quot;", '"')
              end
              characters(chars)
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

            if tag_name.start_with?("/")
              end_element(tag_name[1..]) if responds_to_end_element
            elsif args.nil?
              start_element(tag_name, nil)
            else
              start_element(tag_name, args.scan(ATTR_REGEX).each_with_object({}) { |m, h| h[m[1].to_sym] = m[2] })
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
