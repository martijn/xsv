# frozen_string_literal: true

module Xsv
  # RelationshipsHandler parses the "xl/_rels/workbook.xml.rels" file to get the existing relationships.
  # This is used internally  when opening a workbook.
  class RelationshipsHandler < SaxParser
    def self.get_relations(io)
      relations = []

      new { |relation| relations << relation }.parse(io)

      relations
    end

    def initialize(&block)
      @block = block
    end

    def start_element(name, attrs)
      @block.call(attrs.slice(:Id, :Type, :Target)) if name == 'Relationship'
    end
  end
end
