require "hyp_diff/text_from_node"

module HypDiff

describe TextFromNode do

  let(:node) { double }
  let(:other_node) { double }

  let(:subject) { TextFromNode.new("spam", node) }
  let(:same_text_other_node) { TextFromNode.new("spam", other_node) }
  let(:other_text_same_node) { TextFromNode.new("eggs", node) }

  it "equals other instance when text is equal" do
    subject.should == same_text_other_node
    subject.should be_eql(same_text_other_node)

    subject.should_not == other_text_same_node
    subject.should_not be_eql(other_text_same_node)
  end

  it "provides a sane hash implementation" do
    subject.hash.should == same_text_other_node.hash
    subject.hash.should_not == other_text_same_node.hash
  end

end

end
