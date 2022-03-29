# frozen_string_literal: true

module Xsv
  class SaxParser
    ATTR_REGEX = /((\p{Alnum}+)="(.*?)")/mn

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

            stripped_tag_name = strip_namespace(tag_name)

            if tag_name.start_with?("/")
              end_element(strip_namespace(tag_name[1..])) if responds_to_end_element
            elsif args.nil?
              start_element(stripped_tag_name, nil)
            else
              start_element(stripped_tag_name, args.scan(ATTR_REGEX).each_with_object({}) { |(_, k, v), h| h[k.to_sym] = v })
              end_element(stripped_tag_name) if responds_to_end_element && args.end_with?("/")
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

    private

    # I am not proud of this, but there's simply no need to deal with xmlns for this application ¯\_(ツ)_/¯
    def strip_namespace(tag)
      if (offset = tag.index(":"))
        tag[offset + 1..]
      else
        tag
      end
    end
  end
end
