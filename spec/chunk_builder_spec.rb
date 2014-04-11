require "hyp_diff/chunk_builder"

module HypDiff

describe ChunkBuilder do

  def change_double(action, text, old_text = nil)
    case action
    when "="
      double(action: action, new_element: double(text: text))
    when "+"
      double(action: action, new_element: double(text: text))
    when "-"
      double(action: action, old_element: double(text: text))
    when "!"
      double(action: action, old_element: double(text: text), new_element: double(text: old_text))
    end
  end

  it "merges consecutive chunks at the end" do
    ChunkBuilder.build_chunks_for([
      change_double("=", "foo"),
      change_double("=", "bar")
    ]).should == [ChunkBuilder::EqualChunk.new(["foo", "bar"])]
  end

  it "merges consecutive chunks followed by insertions" do
    ChunkBuilder.build_chunks_for([
      change_double("=", "foo"),
      change_double("=", "bar"),
      change_double("+", "buz")
    ]).should == [
      ChunkBuilder::EqualChunk.new(["foo", "bar"]),
      ChunkBuilder::DiffChunk.new([], ["buz"])
    ]
  end

  it "merges consecutive chunks followed by deletions" do
    ChunkBuilder.build_chunks_for([
      change_double("=", "foo"),
      change_double("=", "bar"),
      change_double("-", "buz")
    ]).should == [
      ChunkBuilder::EqualChunk.new(["foo", "bar"]),
      ChunkBuilder::DiffChunk.new(["buz"], [])
    ]
  end

  it "merges consecutive chunks before edits" do
    ChunkBuilder.build_chunks_for([
      change_double("=", "foo"),
      change_double("=", "bar"),
      change_double("!", "buz", "baz")
    ]).should == [
      ChunkBuilder::EqualChunk.new(["foo", "bar"]),
      ChunkBuilder::DiffChunk.new(["buz"], ["baz"])
    ]
  end

end

end
