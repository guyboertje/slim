module Slim
module TagOutput
  extend self

  def try(parser, scanner, current_indent, tags)

    unless indicator = scanner.scan(%r~ *=(=?)('?)\s?~)
      return false
    end

    single = scanner.m1.empty?
    add_ws = !scanner.m2.empty?

    lines = scanner.shift_broken_lines
    scanner.liner.advance(lines.count(?\n))

    next_indent = scanner.check_next_indent
    
    if next_indent > current_indent
      block = [:multi]
      tags.push [:slim, :output, single, lines, block]
      parser.last_push [:static, ' '] if add_ws
      parser.push block
    else
      tags.push [:slim, :output, single, lines, [:multi, [:newline]]]
      parser.last_push [:static, ' '] if add_ws
    end

    # ap from: "TagOutput", lines: lines

    true
  end
end
end

