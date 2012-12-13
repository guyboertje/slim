
module Slim
module InlineHtml
  extend self
  def try(parser, scanner, current_indent)
    # ap "inline html"
    unless line = scanner.scan(%r{<.+>})
      return false
    end
    block = [:multi]
    parser.last_push [:multi, [:slim, :interpolate, line], block]
    parser.push block
    true
  end
end
end
