# frozen_string_literal: true

module Xsv
  class SaxParser
    ATTR_REGEX = /((\S+)="(.*?)")/m.freeze

    def parse(io)
      @start_element = respond_to?(:start_element) ? method(:start_element) : nil
      @end_element = respond_to?(:end_element) ? method(:end_element) : nil
      @characters = respond_to?(:characters) ? method(:characters) : nil

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
          if (o = pbuf.index('<'))
            chars = pbuf.slice!(0, o + 1).chop!
            @characters&.call(chars) unless chars.empty?

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
          if o = pbuf.index('>')
            tag_name, args = pbuf.slice!(0, o + 1).chop!.split(' ', 2)

            if tag_name.start_with?('/')
              @end_element&.call(tag_name[1..-1])
            else
              if args.nil?
                @start_element&.call(tag_name, nil)
              else
                @start_element&.call(tag_name, args.scan(ATTR_REGEX).each_with_object({}) { |m, h| h[m[1].to_sym] = m[2] })
                @end_element&.call(tag_name) if args.end_with?('/')
              end
            end

            state = :look_start
          elsif eof_reached
            raise 'Malformed XML document, looking for end of tag beyond EOF'
          else
            must_read = true
          end
        end
      end
    end
  end
end
