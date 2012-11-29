
module Slim
module SlimComment
  extend self
  def try(parser, scanner)
    scanner.indentation
    unless comment = scanner.scan(%r{/})
      return false
    end
    scanner.line_end(false)
    min_indent = scanner.current_indent.succ

    if block = scanner.scan(%r{(\r?\n)* {#{min_indent},}.*(\r?\n+)*})
      lines = block.count(?\n)
      scanner.liner.advance(lines)
    end
    true
  end
end
end
