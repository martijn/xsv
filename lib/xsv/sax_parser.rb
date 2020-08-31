module Xsv
  class SaxParser
    def emit(callback, *args)
      @callbacks[callback]&.call(*args)
    end

    def parse_args(args)
      return nil if args.nil?

      args.scan(/((\S+)\=\"(.*?)\")/).map { |m| m[1..2] }.to_h
    end

    def parse(io)
      @callbacks = {
        start_element: respond_to?(:start_element) ? method(:start_element) : nil,
        end_element: respond_to?(:end_element) ? method(:end_element) : nil,
        characters: respond_to?(:characters) ? method(:characters) : nil
      }

      pbuf = String.new("", capacity: 768)
      state = :look_start
      is_close = false
      is_selfclose = false
      eof_reached = false
      force_read = false

      pbuf = io.dup if io.is_a?(String)

      while !eof_reached || !pbuf.empty?
        begin
          # Keep buffer size below 768 bytes, unless we need more to progress to the next state
          if force_read || pbuf.length < 128
            pbuf << io.sysread(512)
            force_read = false
          end
        rescue EOFError, TypeError, NoMethodError
          # EOFError is thrown by IO
          # When reading from zip no EOFError is thrown, instead systead returns nil
          # When reading from a String there is no sysread method
          eof_reached = true
        end

        case state
        when :look_start
          if o = pbuf.index("<")
            chars = pbuf.slice!(0, o+1).chop
            emit(:characters, chars) unless chars.empty?

            is_close = pbuf[0] == "/"
            state = :look_end
          else
            force_read = true
          end
        when :look_end
          if o = pbuf.index(">")
            tag_name, args = pbuf.slice!(0, o+1).chop.split(" ", 2)
            is_selfclose = args ? args[-1] == "/" : nil

            if is_close
              emit(:end_element, tag_name[1..-1])
            else
              emit(:start_element, tag_name, parse_args(args))
              emit(:end_element, tag_name) if is_selfclose
            end
            state = :look_start
          else
            force_read = true
          end
        end

        # Don't hang on trailing newline
        pbuf.clear if eof_reached && state == :look_start && pbuf.size < 3
      end
    end
  end
end
