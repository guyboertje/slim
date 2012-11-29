
module Slim
module HtmlConditionalComment
  extend self
  def try(parser, scanner)
    scanner.indentation
    unless comment = scanner.scan(%r{/\[(?=.+\])})
      return false
    end
    txt = scanner.scan(%r{.+\].*}).strip.sub(?],'')
    scanner.line_end(false)
    block = [:multi]
    parser.build [:html, :condcomment, txt, block]
    parser.push block
    true
  end
end
end
