require "nokogiri"
require "diff-lcs"

require "hyp_diff/text_from_node"

module HypDiff; class << self

  def compare(before, after, options = {})
    parsed_after = parse(after)
    parsed_before = parse(before)

    text_changes = Diff::LCS.sdiff(extract_text(parsed_before), extract_text(parsed_after))

    change_node_tuples = text_changes.map do |change|
      [change, change.new_element && change.new_element.node]
    end

    render_deletion = options[:render_deletion] || proc { |html| "<del>#{html}</del>" }
    render_insertion = options[:render_insertion] || proc { |html| "<ins>#{html}</ins>" }

    NodeMap.for(change_node_tuples).each do |node, changes|
      node.replace(ChangeRenderer.render(changes, render_deletion, render_insertion))
    end

    parsed_after.to_html
  end

  private

  class NodeMap
    def self.for(change_node_tuples, &block)
      new.build(change_node_tuples).map
    end

    attr_reader :map

    def initialize
      @map = {}
      @stashed = []
    end

    def build(change_node_tuples)
      change_node_tuples.each do |change, node|
        if node
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
    def self.render(changes, render_deletion, render_insertion)
      renderer = new(render_deletion, render_insertion).render(changes).rendered_text
    end

    def initialize(render_deletion, render_insertion)
      @new_text = []
      @render_deletion = render_deletion
      @render_insertion = render_insertion
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
      @render_insertion.call(text)
    end

    def deletion_tag(text)
      @render_deletion.call(text)
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

