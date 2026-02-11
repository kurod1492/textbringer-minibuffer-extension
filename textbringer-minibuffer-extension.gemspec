# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "textbringer/minibuffer_extension/version"

Gem::Specification.new do |spec|
  spec.name          = "textbringer-minibuffer-extension"
  spec.version       = Textbringer::MinibufferExtension::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "Minibuffer extensions for Textbringer."
  spec.description   = "Provides minibuffer history navigation and other enhancements for Textbringer."
  spec.homepage      = "https://github.com/yourusername/textbringer-minibuffer-extension"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "textbringer", ">= 1.4"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", ">= 12.0"
  spec.add_development_dependency "test-unit"
end
