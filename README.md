# HypDiff

HypDiff compares HTML snippets. It generates a diff between two input snippets. The diff is a new HTML snippet that highlights textual changes. The tag structure and formatting of the input snippets is preserved. The generated diff snippet is valid, well-formed HTML and suitable for presentation inside a WYSIWYG environment.

## Usage

    # compare using the defaults: <ins> and <del> tags are inserted into the markup
    HypDiff.compare("<p>byebye world</p>", "<p>hello world</p>")
    # => '<p><del>byebye</del><ins>hello</ins> world</p> '

    # use custom markup by providing callbacks for rendering insertions and deletions
    HypDiff.compare("<p>byebye world</p>", "<p>hello world</p>",
      render_insertion: proc { |html| "<span data-diff='ins'>#{html}</span>" },
      render_deletion: proc { |html| "<span data-diff='del'>#{html}</span>" }
    )
    # '<p><span data-diff='del'>byebye</span><span data-diff='ins'>hello</span> world</p> '

    # choose which markup should be the basis for the results:
    HypDiff.compare("<div>byebye world</div>", "<p>hello world</p>", markup_from: "before")
    # => '<div><del>byebye</del><ins>hello</ins> world</div> '
    HypDiff.compare("<div>byebye world</div>", "<p>hello world</p>", markup_from: "after")
    # => '<p><del>byebye</del><ins>hello</ins> world</p> '

For more examples, take a look at the [specs](https://github.com/krishan/hyp_diff/blob/master/spec/hyp_diff_spec.rb).

## Why another diff tool?

Many existing tools simply create a diff of the html source code. Unfortunately a diff of the source code can only be viewed as source code. It cannot be viewed in a browser. While that is fine for developers, it is not suitable for an audience that prefers not to be exposed to HTML source code, for example users of WYSIWYG editors.

There are other tools that try to generate an HTML diff that is can be rendered by a browser. But many tools simply try to "work around" the HTML document structure by use of regular expressions. This simplistic approach only works for a small subset of HTML snippets. These tools often output incomprehensible diffs or even invalid HTML.

## How is HypDiff different?

HypDiff takes two HTML snippets and generates a comparison that is again a valid HTML snippet that can be viewed inside a browser.

HypDiff does not rely on regular expressions, but actually parses the input snippets using Nokogiri. It extracts the textual content of the documents and compares them with a state-of-the-art diff algorithm provided by the diff-lcs gem. It then inserts `<ins>` and `<del>` tags into the HTML snippet to highlight changes, but leaves all other HTML tags intact.

## Limitations

HypDiff does not perform a comparison of the html source code or the DOM tree, but compares changes to visible text. It does not care about changes that do not involve visible text.

## Installation

Add this line to your application's Gemfile:

    gem 'hyp_diff'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hyp_diff

## Contributing

1. Fork it ( http://github.com/krishan/hyp_diff/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Copyright 2014 Kristian Hanekamp
