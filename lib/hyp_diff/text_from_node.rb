module HypDiff

class TextFromNode
  attr_accessor :before_whitespace

  def initialize(raw_text, node)
    @text = raw_text.strip == "" ? " " : raw_text
    @node = node
  end

  def ==(other)
    eql?(other)
  end

  def eql?(other)
    text == other.text
  end

  def hash
    text.hash
  end

  def whitespace?
    @text == " "
  end

  def fulltext
    before_whitespace ? " #{text}" : text
  end

  def text
    @text
  end

  def node
    @node
  end
end

end
