# frozen_string_literal: true

module Xsv
  class SaxParser
    def parse(io)
      @callbacks = {
        start_element: respond_to?(:start_element) ? method(:start_element) : nil,
        end_element: respond_to?(:end_element) ? method(:end_element) : nil,
        characters: respond_to?(:characters) ? method(:characters) : nil
      }.freeze

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
            pbuf << io.sysread(4096)
          rescue EOFError, TypeError
            # EOFError is thrown by IO, rubyzip returns nil from sysread on EOF
            eof_reached = true
          end

          must_read = false
        end

        if state == :look_start
          if o = pbuf.index('<')
            chars = pbuf.slice!(0, o+1).chop
            @callbacks[:characters]&.call(chars) unless chars.empty?

            state = :look_end
          else
            if eof_reached
              # Discard anything after the last tag in the document
              break
            else
              # Continue loop to read more data into the buffer
              must_read = true
              next
            end
          end
        end

        if state == :look_end
          if o = pbuf.index('>')
            tag_name, args = pbuf.slice!(0, o+1).chop.split(' ', 2)

            if tag_name.start_with?('/')
              @callbacks[:end_element]&.call(tag_name[1..-1])
            else
              if args.nil?
                @callbacks[:start_element]&.call(tag_name, nil)
              else
                @callbacks[:start_element]&.call(tag_name, args.scan(/((\S+)\=\"(.*?)\")/m).map { |m| [m[1].to_sym, m[2]] }.to_h)
                @callbacks[:end_element]&.call(tag_name) if args.end_with?('/')
              end
            end

            state = :look_start
          else
            if eof_reached
              raise 'Malformed XML document, looking for end of tag beyond EOF'
            else
              must_read = true
            end
          end
        end
      end
    end
  end
end
