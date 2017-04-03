# encoding: utf-8
require "hyp_diff"

describe HypDiff do

  def expect_diff(old, new, expected)
    expect(HypDiff.compare(old, new)).to eq(expected)
  end

  it "diffs two texts, applying tags to indicate changes" do
    expect_diff("byebye", "hello", '<del>byebye</del><ins>hello</ins>')
  end

  it "extracts text to diff from input markup, reapplying the (after-)markup to the diff" do
    expect_diff(
      "<b>byebye</b> world",
      "<i>hello</i> world",
      '<i><del>byebye</del><ins>hello</ins></i> world'
    )
  end

  it "diffs word-by-word" do
    expect_diff("byebye world", "hello world", '<del>byebye</del><ins>hello</ins> world')
  end

  it "handles pure additions" do
    expect_diff("hello ", "hello world", 'hello <ins>world</ins>')
  end

  it "handles pure deletions" do
    expect_diff("hello world", "hello ", 'hello <del>world</del>')
  end

  it "handles pure deletions at the beginning" do
    expect_diff("hello world", " world", '<del>hello</del> world')
  end

  it "handles several pure deletions at the beginning" do
    expect_diff("hello beautiful world", "world", '<del>hello beautiful </del>world')
  end

  it "merges consecutive additions into a single tag" do
    expect_diff(
      "hello world",
      "why hello beautiful world",
      "<ins>why </ins>hello<ins> beautiful</ins> world"
    )
  end

  it "merges consecutive deletions into a single tag" do
    expect_diff("hello beautiful world", "hello world", "hello <del>beautiful </del>world")
  end

  it "merge consecutive additions and edits into single tags" do
    expect_diff(
      "hello world",
      "hello my beautiful",
      "hello <del>world</del><ins>my beautiful</ins>"
    )
  end

  it "merge consecutive deletions and edits into single tags" do
    expect_diff(
      "hello my beautiful",
      "hello world",
      "hello <del>my beautiful</del><ins>world</ins>"
    )
  end

  describe "with callbacks for custom markup" do
    it "uses them to generate the insertions and deletions" do
      expect(HypDiff.compare(
        "byebye world",
        "hello world",
        render_insertion: proc { |html| "<new>#{html}</new>" },
        render_deletion: proc { |html| "<old>#{html}</old>" }
      )).to eq(
        "<old>byebye</old><new>hello</new> world"
      )
    end
  end

  describe "choosing which markup to use" do
    it "allows to choose 'after'" do
      expect(HypDiff.compare(
        "<b>byebye world</b>",
        "<i>hello world</i>",
        markup_from: "after"
      )).to eq(
        "<i><del>byebye</del><ins>hello</ins> world</i>"
      )
    end

    it "allows to choose 'before'" do
      expect(HypDiff.compare(
        "<b>byebye world</b>",
        "<i>hello world</i>",
        markup_from: "before"
      )).to eq(
        "<b><del>byebye</del><ins>hello</ins> world</b>"
      )
    end
  end

  describe "handling html entities" do
    it "handles them transparently when whole words are entities" do
      expect_diff(
        "foo &lt; bar",
        "foo &gt; bar",
        "foo <del>&lt;</del><ins>&gt;</ins> bar"
      )
    end

    it "handles them transparently when words contain entities" do
      expect_diff(
        "f&#252; b&#228;r",
        "f&#246; b&#228;r",
        "<del>fü</del><ins>fö</ins> bär"
      )
    end
  end

  describe "handling whitespace" do
    it "treats consecutive whitespace as a single whitespace" do
      expect_diff("hello  world", "hello world", "hello world")
    end

    it "treats consecutive whitespace as a single whitespace across tags" do
      expect_diff(
        "<span>hello </span> <span> world</span>",
        "hello world",
        "hello world"
      )
      expect_diff(
        "<span>hello </span>world",
        "hello<span> world</span>",
        "hello<span> world</span>"
      )
    end

    it "considers trailing and leading whitespace for insertions and deletions" do
      expect_diff("hello", "hello world", "hello<ins> world</ins>")
      expect_diff("hello world", "hello", "hello<del> world</del>")
      expect_diff("world", "hello world", "<ins>hello </ins>world")
      expect_diff("hello world", "world", "<del>hello </del>world")
      expect_diff(" world", "hello world", "<ins>hello</ins> world")
      expect_diff("hello world", " world", "<del>hello</del> world")
      expect_diff("hello ", "hello world", "hello <ins>world</ins>")
      expect_diff("hello world", "hello ", "hello <del>world</del>")
    end

    it "considers trailing and leading whitespace changes" do
      expect_diff("hello ", "hello", "hello<del> </del>")
      expect_diff("hello", "hello ", "hello<ins> </ins>")
      expect_diff(" hello", "hello", "<del> </del>hello")
      expect_diff("hello", " hello", "<ins> </ins>hello")
    end

    it "considers changes of text and whitespace" do
      expect_diff("hello world ", "hello friend", "hello <del>world </del><ins>friend</ins>")
      expect_diff(" bye world", "hello world", "<del> bye</del><ins>hello</ins> world")
      expect_diff("hello friend", "hello world ", "hello <del>friend</del><ins>world </ins>")
      expect_diff("hello world", " bye world", "<del>hello</del><ins> bye</ins> world")
    end
  end

  it "diffs punctuation signs as single tokens when followed by whitespace" do
    expect_diff("hello world", "hello, world", "hello<ins>,</ins> world")
  end

  it "diffs changes of punctuation to words" do
    expect_diff(
      "hello, world",
      "hello beautiful world",
      "hello<del>,</del><ins> beautiful</ins> world"
    )
    expect_diff(
      "hello beautiful world",
      "hello, world",
      "hello<del> beautiful</del><ins>,</ins> world"
    )
  end

  it "diffs changes of punctuation to leading and trailing spaces" do
    expect_diff("hello.", "hello ", "hello<del>.</del><ins> </ins>")
    expect_diff("hello ", "hello.", "hello<del> </del><ins>.</ins>")
    expect_diff(" hello", ".hello", "<del> </del><ins>.</ins>hello")
    expect_diff(".hello", " hello", "<del>.</del><ins> </ins>hello")
  end

  it "diffs punctuation signs as single tokens when at end of string" do
    expect_diff("hello world", "hello world.", "hello world<ins>.</ins>")
  end

end
