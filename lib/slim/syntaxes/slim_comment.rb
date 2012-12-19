
module Slim
module SlimComment
  extend self
  def try(parser, scanner, current_indent)

    unless comment = scanner.scan(%r{/})
      return false
    end
    scanner.shift_text
    scanner.line_end(false)
    min_indent = scanner.current_indent.succ

    scanner.shift_indented_lines(min_indent)

    true
  end
end
end
