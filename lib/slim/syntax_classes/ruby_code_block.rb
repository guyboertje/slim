
module Slim
module RubyCodeBlock
  extend self
  def try(parser, scanner)
    scanner.indentation
    unless indicator = scanner.scan(%r{-})
      return false
    end
    line = scanner.scan_text
    scanner.line_end(false)
    block = [:multi]
    out = [:multi]
    # parse broken line



    parser.build [:multi, [:slim, :interpolate, out], block]
    parser.push block
    true
  end
end
end
