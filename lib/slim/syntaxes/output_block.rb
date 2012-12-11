module Slim
module OutputBlock
  extend self
  def try(parser, scanner, current_indent)
    unless indicator = scanner.scan(%r~=(=?)('?)~)
      return false
    end

    single = scanner.m1.empty?
    add_ws = !scanner.m2.empty?

    lines = scanner.shift_broken_lines
    scanner.liner.advance(lines.count(?\n))

    next_indent = scanner.check_next_indent
    
    if next_indent > current_indent
      block = [:multi]
      parser.build [:slim, :output, single, lines, block]
      parser.build [:static, ' '] if add_ws
      parser.push block
    else
      parser.build [:slim, :output, single, lines, [:multi, [:newline]]]
      parser.build [:static, ' '] if add_ws
    end

    true
  end
end
end
