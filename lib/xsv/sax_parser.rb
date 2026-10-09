# frozen_string_literal: true

require "cgi"

module Xsv
  # Minimal streaming XML parser, optimized for the XML found in xlsx files. Subclasses implement
  # `start_element(name, attrs)` and optionally `end_element(name)` and `characters(value)`.
  #
  # The document is read in chunks into a buffer. Instead of consuming the buffer from the front,
  # the parser moves a cursor through it using byte offsets and only compacts it when the next
  # chunk is appended, so each byte is scanned a constant number of times. Strings are only
  # allocated for values that are passed to the callbacks.
  class SaxParser
    CHUNK_SIZE = 65_536

    # `while true` is used instead of `loop`, because it avoids a block call per iteration
    # standard:disable Style/InfiniteLoop
    def parse(io)
      responds_to_end_element = respond_to?(:end_element)
      responds_to_characters = respond_to?(:characters)

      if io.is_a?(String)
        buf = io.dup.force_encoding(Encoding::UTF_8)
        eof_reached = true
      else
        buf = String.new(capacity: CHUNK_SIZE * 2, encoding: Encoding::UTF_8)
        eof_reached = false
      end

      pos = 0 # start of the unparsed data in buf
      gt = 0 # position of the previous ">" in buf

      # Positions of the next occurrence of these characters in buf. Caching them keeps the
      # searches linear when a character is absent from a stretch of the document. The buffer
      # size is cached when there are no more occurrences, so that comparisons never match.
      space = -1
      equals = -1 # '="'
      colon = -1

      # Searches for a character always start at a delimiter, never right after one: byteindex
      # requires its offset to be at a character boundary, and that might not be the case
      # right after a delimiter in a document containing invalid UTF-8.
      while true
        # Find the next complete tag, reading more data if necessary
        lt = buf.byteindex("<", gt)
        gt = lt && buf.byteindex(">", lt)

        unless gt
          if eof_reached
            raise Xsv::Error, "Malformed XML document, looking for end of tag beyond EOF" if lt
            # Discard anything after the last tag in the document
            break
          end

          # Drop the parsed data and append the next chunk. Multi-byte UTF-8 characters split
          # across chunks are reassembled here, so only complete characters are emitted.
          buf = buf.byteslice(pos, buf.bytesize - pos) if pos > 0
          pos = 0
          gt = 0
          space = equals = colon = -1

          begin
            chunk = io.sysread(CHUNK_SIZE)
            if chunk
              buf << chunk.force_encoding(Encoding::UTF_8)
            else
              # rubyzip < 3 returns nil from sysread on EOF
              eof_reached = true
            end
          rescue EOFError
            # EOFError is thrown by IO and rubyzip >= 3
            eof_reached = true
          end

          next
        end

        if responds_to_characters && lt > pos
          chars = buf.byteslice(pos, lt - pos)
          characters(chars.include?("&") ? CGI.unescapeHTML(chars) : chars)
        end

        pos = gt + 1

        space = buf.byteindex(" ", lt) || buf.bytesize if space < lt
        colon = buf.byteindex(":", lt) || buf.bytesize if colon < lt

        if buf.getbyte(lt + 1) == 47 # "/"
          # Strip XML namespace from tag
          name_start = (colon < gt) ? colon + 1 : lt + 2
          end_element(buf.byteslice(name_start, gt - name_start)) if responds_to_end_element
          next
        end

        name_end = (space < gt) ? space : gt
        name_start = (colon < name_end) ? colon + 1 : lt + 1
        tag_name = buf.byteslice(name_start, name_end - name_start)

        if space > gt
          start_element(tag_name, nil)
          next
        end

        # Parse attributes, from the space after the tag name or the closing quote of the previous value
        attributes = {}
        attr_start = space
        while true
          equals = buf.byteindex('="', attr_start) || buf.bytesize if equals < attr_start
          break if equals > gt

          quote = begin
            buf.byteindex('"', equals + 2)
          rescue IndexError
            # The value starts with an invalid UTF-8 byte
            buf.b.byteindex('"', equals + 2)
          end
          break if quote.nil? || quote > gt

          colon = buf.byteindex(":", attr_start) || buf.bytesize if colon < attr_start

          if colon < equals
            # Strip XML namespace from attribute name
            key = buf.byteslice(colon + 1, equals - colon - 1)
          else
            key = buf.byteslice(attr_start + 1, equals - attr_start - 1)
            key.lstrip!
          end

          attributes[key.to_sym] = buf.byteslice(equals + 2, quote - equals - 2)
          attr_start = quote
        end

        start_element(tag_name, attributes)
      end
    end
    # standard:enable Style/InfiniteLoop
  end
end
