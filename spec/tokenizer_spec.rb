require "hyp_diff/tokenizer"

module HypDiff

describe Tokenizer do

  it "tokenizes words punctuation and whitespace" do
    Tokenizer.tokenize(" hello, world ").should == ["", "hello", ",", "world", ""]
  end

  it "tokenizes all kinds of punctuation" do
    Tokenizer.tokenize("!?.;\"'()`").should == %w[! ? . ; " ' ( ) `]
  end

  it "treats consecutive whitespace as single whitespace" do
    Tokenizer.tokenize("   X    ").should == ["", "X", ""]
  end

  it "treats just whitespace as a single whitespace" do
    Tokenizer.tokenize("    ").should == [""]
  end

end

end


