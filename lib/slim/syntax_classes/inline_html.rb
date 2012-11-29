
module Slim
module InlineHtml
  extend self
  def try(parser, scanner)
    scanner.indentation
    unless indicator = scanner.scan(%r{<})
      return false
    end
    txt = scanner.scan_text
    scanner.line_end(false)
    txt.prepend(indicator)
    block = [:multi]
    parser.build [:multi, [:slim, :interpolate, txt], block]
    parser.push block
    true
  end
end
end
