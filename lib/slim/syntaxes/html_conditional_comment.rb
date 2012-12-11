
module Slim
module HtmlConditionalComment
  extend self
  def try(parser, scanner, current_indent)
    # ap "html conditional comment"
    unless comment = scanner.scan(%r{/\[\s*(.*?) *\].*(?=\r?\n)})
      return false
    end
    ap from: "HtmlConditionalComment", comment: comment
    txt = scanner.m1
    block = [:multi]
    parser.build [:html, :condcomment, txt, block]
    parser.push block
    true
  end
end
end
