require "hyp_diff/text_from_node"

module HypDiff

describe TextFromNode do

  let(:node) { double }
  let(:other_node) { double }

  let(:subject) { TextFromNode.new("spam", node) }
  let(:same_text_other_node) { TextFromNode.new("spam", other_node) }
  let(:other_text_same_node) { TextFromNode.new("eggs", node) }

  it "equals other instance when text is equal" do
    expect(subject).to eq(same_text_other_node)
    expect(subject).to be_eql(same_text_other_node)

    expect(subject).not_to eq(other_text_same_node)
    expect(subject).not_to be_eql(other_text_same_node)
  end

  it "provides a sane hash implementation" do
    expect(subject.hash).to eq(same_text_other_node.hash)
    expect(subject.hash).not_to eq(other_text_same_node.hash)
  end

end

end
