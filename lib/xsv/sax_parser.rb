# frozen_string_literal: true

module Xsv
  class SaxParser
    ATTR_REGEX = /((\p{Alnum}+)="(.*?)")/mn

    def parse(io)
      responds_to_end_element = respond_to?(:end_element)
      responds_to_characters = respond_to?(:characters)

      loop do
        if (chars = io.gets("<")&.chomp("<"))
          break if io.eof? # Ignore trailing whitespace/newlines after last tag

          if responds_to_characters && !chars.empty?
            if chars.index("&")
              chars.gsub!("&amp;", "&")
              chars.gsub!("&apos;", "'")
              chars.gsub!("&gt;", ">")
              chars.gsub!("&lt;", "<")
              chars.gsub!("&quot;", '"')
            end
            characters(chars.force_encoding("UTF-8"))
          end
        else
          # EOF reached
          break
        end

        if (tag = io.gets(">"))
          raise Xsv::Error, "Malformed XML document, looking for end of tag beyond EOF" unless tag.end_with?(">")
          tag.chomp!(">")

          tag_name, _, args = tag.partition(" ")
          stripped_tag_name = strip_namespace(tag_name)

          if tag_name.start_with?("/")
            end_element(strip_namespace(tag_name[1..])) if responds_to_end_element
          elsif args&.empty?
            start_element(stripped_tag_name, nil)
          else
            start_element(stripped_tag_name, args.scan(ATTR_REGEX).each_with_object({}) { |(_, k, v), h| h[k.to_sym] = v })
            end_element(stripped_tag_name) if responds_to_end_element && args.end_with?("/")
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
