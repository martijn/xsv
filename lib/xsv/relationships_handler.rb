# frozen_string_literal: true
module Xsv
  # RelationshipsHandler parses the "xl/_rels/workbook.xml.rels" file to get the existing relationships.
  # This is used internally  when opening a workbook.
  class RelationshipsHandler < Ox::Sax
    def self.get_relations(io)
      relations = []
      handler = new do |relation|
        relations << relation
      end

      Ox.sax_parse(handler, io.read)
      return relations
    end

    # Ox::Sax implementation

    def initialize(&block)
      @block = block
      @relationship = {}
    end

    def start_element(name)
      @relationship = {} if name == :Relationship
    end

    def attr(name, value)
      case name
      when :Id, :Type, :Target
        @relationship[name] = value
      end
    end

    def end_element(name)
      return unless name == :Relationship

      @block.call(@relationship)
    end
  end
end
