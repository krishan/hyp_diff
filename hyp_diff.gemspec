# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyp_diff/version'

Gem::Specification.new do |spec|
  spec.name          = "hyp_diff"
  spec.version       = HypDiff::VERSION
  spec.authors       = ["Kristian Hanekamp"]
  spec.email         = ["kris.hanekamp@gmail.com"]
  spec.summary       = %q{HypDiff compares html snippets}
  spec.description   = %q{
HypDiff compares HTML snippets. It generates a diff between two input snippets. The diff is a new HTML snippet that highlights textual changes. The tag structure and formatting of the input snippets is preserved. The generated diff snippet is valid, well-formed HTML and suitable for presentation inside a WYSIWYG environment.
  }
  spec.homepage      = "https://github.com/krishan/hyp_diff"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.6.5"
  spec.add_dependency "diff-lcs", "~> 1.2.5"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rspec", "~> 2.14.1"
  spec.add_development_dependency "rake", "~> 10.1"
end
