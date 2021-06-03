# encoding: utf-8
require "hyp_diff"
require "securerandom"

describe HypDiff do
  context "for large text" do
    it "performs reasonably fast" do
      words = []
      300.times do
        8.times do |i|
          words << SecureRandom.hex([i + 2, 6].min)
        end
        words << "replace"
        words << "me."
      end
      text = words.join(" ")
      modified_text = text.gsub("replace me", "better text")
      start = Time.now

      HypDiff.compare(text, modified_text)
      expect(Time.now - start).to be < 1
    end
  end
end
