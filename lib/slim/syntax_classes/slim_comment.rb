
module Slim
module SlimComment
  extend self
  def try(parser, scanner)
    # ap "slim comment"
    unless comment = scanner.scan(%r{/})
      return false
    end
    scanner.shift_text
    scanner.line_end(false)
    min_indent = scanner.current_indent.succ

    if block = scanner.shift_indented_lines(min_indent)
      lfs = block.count(?\n)
      scanner.liner.advance(lfs)
    end
    true
  end
end
end
