require "nokogiri"
require "diff-lcs"

require "hyp_diff/text_from_node"

# @api public
module HypDiff; class << self

  # Compare two html snippets.
  # @param before [String] the first html snippet
  # @param after [String] the second html snippet
  # @option options [Proc] :render_insertion provide a callback to render insertions. The callback will receive the inserted text as a html snippet. It should return a new html snippet that will be used in the output. If no callback is given, `<ins>`-Tags will be used to highlight insertions.
  # @option options [Proc] :render_deletion provide a callback to render deletions. The callback will receive the deleted text as a html snippet. It should return a new html snippet that will be used in the output. If no callback is given, `<del>`-Tags will be used to highlight deletions.
  # @option options [String] :markup_from specify if the markup from `before` or `after` should be used as the basis for the output. Possible values: "before" and "after". Default: "after"
  # @return [String] a new html snippet that highlights changes between `before` and `after`
  # @api public
  def compare(before, after, options = {})
    parsed_after = parse(after)
    parsed_before = parse(before)

    text_changes = Diff::LCS.sdiff(extract_text(parsed_before), extract_text(parsed_after))

    markup_from_before = options[:markup_from] == "before"

    change_node_tuples = text_changes.map do |change|
      text_from_node = markup_from_before ? change.old_element : change.new_element
      [change, text_from_node && text_from_node.node]
    end

    render_deletion = options[:render_deletion] || proc { |html| "<del>#{html}</del>" }
    render_insertion = options[:render_insertion] || proc { |html| "<ins>#{html}</ins>" }

    NodeMap.for(change_node_tuples).each do |node, changes|
      node.replace(ChangeRenderer.render(changes, render_deletion, render_insertion))
    end

    modified_fragment = markup_from_before ? parsed_before : parsed_after
    modified_fragment.to_html
  end

  private

  # @api private
  class NodeMap
    def self.for(change_node_tuples)
      new.build(change_node_tuples).map
    end

    attr_reader :map

    def initialize
      @map = Hash.new {|h, k| h[k] = [] }
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
      @map[node] << change
    end
  end

  # @api private
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
          old_fulltext = change.old_element.fulltext
          new_fulltext = change.new_element.fulltext
          if old_fulltext.include?(new_fulltext)
            if old_fulltext.start_with?(new_fulltext)
              apply_insertions_and_deletions
              new_text << new_fulltext
              deletions << old_fulltext[new_fulltext.length..-1]
              next
            end
            if old_fulltext.end_with?(new_fulltext)
              deletions << old_fulltext[0, old_fulltext.length - new_fulltext.length]
              apply_insertions_and_deletions
              new_text << new_fulltext
              next
            end
          end
          if new_fulltext.include?(old_fulltext)
            if new_fulltext.start_with?(old_fulltext)
              apply_insertions_and_deletions
              new_text << old_fulltext
              insertions << new_fulltext[old_fulltext.length..-1]
              next
            end
            if new_fulltext.end_with?(old_fulltext)
              insertions << new_fulltext[0, new_fulltext.length - old_fulltext.length]
              apply_insertions_and_deletions
              new_text << old_fulltext
              next
            end
          end
          if insertions.empty? && deletions.empty? && change.old_element.before_whitespace && change.new_element.before_whitespace
            new_text << " "
            deletions << change.old_element.text
            insertions << change.new_element.text
            next
          end
          deletions << change.old_element.fulltext
          insertions << change.new_element.fulltext
        when "=" then
          if change.old_element.before_whitespace && !change.new_element.before_whitespace
            deletions << " "
            apply_insertions_and_deletions
            new_text << change.new_element.text
            next
          end
          if change.new_element.before_whitespace && !change.old_element.before_whitespace
            insertions << " "
            apply_insertions_and_deletions
            new_text << change.new_element.text
            next
          end
          apply_insertions_and_deletions
          new_text << escape_html(change.new_element.fulltext)
        when "+" then
          insertions << change.new_element.fulltext
        when "-" then
          deletions << change.old_element.fulltext
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
      unless deletions.empty? || insertions.empty?
        while !deletions.empty? && !insertions.empty?
          break unless deletions.first == insertions.first

          deletions.shift
          new_text << insertions.shift
        end
      end

      if deletions.length > 0
        new_text << deletion_tag(deletions.join)
      end
      if insertions.length > 0
        new_text << insertion_tag(insertions.join)
      end

      @insertions = []
      @deletions = []
    end

    def insertion_tag(text)
      @render_insertion.call(escape_html(text))
    end

    def deletion_tag(text)
      @render_deletion.call(escape_html(text))
    end

    def escape_html(text)
      fragment = Nokogiri::HTML::DocumentFragment.parse("")
      fragment.content = text
      fragment.to_html
    end

  end

  def parse(text)
    Nokogiri::HTML.fragment(text)
  end

  def extract_text(node)
    merge_whitespace(filter_whitespace(text_fragments(node)))
  end

  def text_fragments(node)
    if node.is_a?(Nokogiri::XML::Text)
      node.text.split(/(?=[.!,<> ])|\b/).map { |token| TextFromNode.new(token, node) }
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

  def merge_whitespace(node_list)
    result = []

    last_whitespace_node = nil
    node_list.each do |node|
      if node.whitespace?
        last_whitespace_node = node
        next
      end

      unless last_whitespace_node
        result << node
        next
      end

      if last_whitespace_node.node.equal?(node.node)
        node.before_whitespace = last_whitespace_node
      else
        result << last_whitespace_node
      end
      last_whitespace_node = nil
      result << node
    end

    result << last_whitespace_node if last_whitespace_node

    result
  end

end; end

