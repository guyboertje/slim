module Slim
module TagText
  extend self

  def try(parser, scanner, tags, memo)
    pos = scanner.position

    unless scanner.scan(%r{\s(.*)(?=\r?\n)})
      scanner.scan_until(/(?=\r?\n)/)
      return true
    end

    tag_txt = scanner.m1

    tag_indent, tag_pos = memo.values_at(:tag_indent, :tag_position)
    min_indent = tag_indent + 1 + (pos - tag_pos)

    out = [:multi]
    out.push [:slim, :interpolate, tag_txt]

    if block = scanner.shift_indented_lines(min_indent)
      block.lines.each do |line|
        next if line =~ /\A\r?\n\z/
        txt = remove_leading_spaces(line, min_indent)
        txt.prepend(?\n) if txt.chomp!
        out.push [:newline]
        out.push([:slim, :interpolate, txt])
      end
    end

    ap from: "OutputBlock", lines: out, dollarslash: $/

    tags.push [:slim, :text, out]

    true
  end

  def remove_leading_spaces(line, amount)
    pieces = line.partition(/\A\s+/)
    count = pieces[1].size
    if count > amount
      pieces[1] = " " * (count - amount)
    else
      pieces[1].clear
    end
    pieces.join
  end
end
end

