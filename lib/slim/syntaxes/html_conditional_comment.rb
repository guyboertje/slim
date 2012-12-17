
module Slim
module HtmlConditionalComment
  extend self
  def try(parser, scanner, current_indent)
    unless comment = scanner.scan(%r{/\[\s*(.*?) *\].*(?=\r?\n)})
      return false
    end
    txt = scanner.m1
    block = [:multi]
    parser.last_push [:html, :condcomment, txt, block]
    parser.push block
    true
  end
end
end
