module HypDiff

class TextFromNode
  def initialize(text, node)
    @text = text
    @node = node
  end

  def ==(other)
    text == other.text
  end

  def eql?(other)
    text == other.text
  end

  def hash
    text.hash
  end

  def whitespace?
    @text == ""
  end

  def text
    @text
  end

  def node
    @node
  end
end

end
