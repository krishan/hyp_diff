require "nokogiri"
require "diff-lcs"

require "text_from_node"

module HypDiff; class << self

  def compare(before, after)
    parsed_after = parse(after)
    parsed_before = parse(before)

    text_changes = Diff::LCS.sdiff(extract_text(parsed_before), extract_text(parsed_after))

    NodeMap.for(text_changes).each do |node, changes|
      node.replace(ChangeRenderer.render(changes))
    end

    parsed_after.to_html
  end

  private

  class NodeMap
    def self.for(changes)
      new.build(changes).map
    end

    attr_reader :map

    def initialize
      @map = {}
      @stashed = []
    end

    def build(changes)
      changes.each do |change|
        if change.new_element
          node = change.new_element.node

          if @stashed.length > 0
            @stashed.each do |stashed_change|
              append_to_node(node, stashed_change)
            end
            @stashed = []
          end

          append_to_node(node, change)

          @last_processed_node = node
        else
          if @last_processed_node
            append_to_node(@last_processed_node, change)
          else
            @stashed << change
          end
        end
      end

      self
    end

    def append_to_node(node, change)
      list = (@map[node] ||= [])
      list << change
    end
  end

  class ChangeRenderer
    def self.render(changes)
      renderer = new.render(changes).rendered_text
    end

    def initialize
      @new_text = []
    end

    def render(changes)
      @insertions = []
      @deletions = []

      changes.each do |change|
        case change.action
        when "!" then
          deletions << change.old_element.text
          insertions << change.new_element.text
        when "=" then
          apply_insertions_and_deletions
          new_text << change.new_element.text
        when "+" then
          insertions << change.new_element.text
        when "-" then
          deletions << change.old_element.text
        else
          raise "unexpected change.action #{change.action}"
        end
      end

      apply_insertions_and_deletions

      self
    end

    def rendered_text
      new_text.join
    end

    private

    attr_reader :insertions, :deletions, :new_text

    def apply_insertions_and_deletions
      if deletions.length > 0
        @new_text << deletion_tag(deletions.join)
      end
      if insertions.length > 0
        @new_text << insertion_tag(insertions.join)
      end

      @insertions = []
      @deletions = []
    end

    def insertion_tag(text)
      "<ins>#{text}</ins>"
    end

    def deletion_tag(text)
      "<del>#{text}</del>"
    end

  end

  def parse(text)
    Nokogiri::HTML.fragment(text)
  end

  def extract_text(node)
    filter_whitespace(text_fragments(node))
  end

  def text_fragments(node)
    if node.is_a?(Nokogiri::XML::Text)
      node.text.split(/(?=[.!, ])|\b/).map { |token| TextFromNode.new(token, node) }
    else
      node.children.map { |c| text_fragments(c) }.flatten
    end
  end

  def filter_whitespace(node_list)
    result = []
    last_node_whitespace = false
    node_list.each do |node|
      node_whitespace = node.whitespace?
      result << node unless last_node_whitespace && node_whitespace

      last_node_whitespace = node_whitespace
    end

    result
  end

end; end

