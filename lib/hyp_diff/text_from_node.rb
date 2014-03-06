module HypDiff

class TextFromNode
  def initialize(raw_text, node)
    @text = raw_text.strip == "" ? " " : raw_text
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
    @text == " "
  end

  def text
    @text
  end

  def node
    @node
  end
end

end
