module Xsv
  class SaxParser
    def parse(io)
      @callbacks = {
        start_element: respond_to?(:start_element) ? method(:start_element) : nil,
        end_element: respond_to?(:end_element) ? method(:end_element) : nil,
        characters: respond_to?(:characters) ? method(:characters) : nil
      }

      state = :look_start

      if io.is_a?(String)
        pbuf = io.dup
        eof_reached = true
      else
        pbuf = String.new("", capacity: 768)
        eof_reached = false
        force_read = true
      end

      while !eof_reached || !pbuf.empty?
        # Keep buffer size below 768 bytes, unless we need more to progress to the next state
        if !eof_reached && (force_read || pbuf.length < 128)
          begin
            pbuf << io.sysread(512)
          rescue EOFError, TypeError
            # EOFError is thrown by IO
            # When reading from zip no EOFError is thrown, instead sysread returns nil
            eof_reached = true
          end
          force_read = false
        end

        if state == :look_start
          if o = pbuf.index("<")
            chars = pbuf.slice!(0, o+1).chop
            @callbacks[:characters]&.call(chars) unless chars.empty?

            is_close = pbuf[0] == "/"
            state = :look_end
          else
            if eof_reached
              # Discard anything after the last tag in the document
              break
            else
              # Break out of loop to read more data into the buffer
              force_read = true
              next
            end
          end
        end

        if state == :look_end
          if o = pbuf.index(">")
            tag_name, args = pbuf.slice!(0, o+1).chop.split(" ", 2)
            is_selfclose = args ? args[-1] == "/" : nil

            if is_close
              @callbacks[:end_element]&.call(tag_name[1..-1])
            else
              if args
                @callbacks[:start_element]&.call(tag_name, args.scan(/((\S+)\=\"(.*?)\")/).map { |m| m.last(2) }.to_h)
              else
                @callbacks[:start_element]&.call(tag_name, nil)
              end
              @callbacks[:end_element]&.call(tag_name) if is_selfclose
            end
            state = :look_start
          else
            if eof_reached
              raise "Malformed XML document, looking for end of tag beyond EOF"
            else
              force_read = true
            end
          end
        end
      end
    end
  end
end
