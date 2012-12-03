module Slim
module RubyCodeBlock
  extend self
  def try(parser, scanner)
    current_indent = scanner.current_indent
    unless indicator = scanner.scan(%r{- ?})
      return false
    end
    lines = scanner.shift_broken_lines
    scanner.liner.advance(lines.count(?\n))
    
    if scanner.check_next_indent > current_indent
      block = [:multi]
      parser.build [:slim, :control, lines, block]
      parser.push block
    else
      parser.build [:slim, :control, lines, [:multi, [:newline]]]
    end
    true
  end
end
end
