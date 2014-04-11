module HypDiff

module Tokenizer

  def self.punctuation?(character)
    # TODO
    character == "," || character == "."
  end

  def self.tokenize(text)
    tokens = text.split(/(?=[!?.;\"'()`,])|\s+/)

    if text.match(/\s$/)
      tokens + [""]
    else
      tokens
    end
  end

end

end
