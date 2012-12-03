# "\n   Another comment\n     \n   Another comment\n\n   Another comment\n"
module Slim
module HtmlComment
  extend self

  def try(parser, scanner)
    # ap "html comment"
    current_indent = scanner.current_indent
    unless comment = scanner.scan(%r{/!( ?)(.*)})
      return false
    end
    out = [:multi]

    offset = current_indent + 2 + scanner.m1.size

    if part = scanner.m2
      part.strip!
      out.push [:slim, :interpolate, part] unless part.empty?
    end

    if block = scanner.shift_indented_lines(offset)
      lines = block.split(/\r?\n/)
      scanner.liner.inc
      lines.shift
      lines.each do |line|
        scanner.liner.inc
        txt = line.slice(offset, line.size) || ""
        out.push [:newline]
        out.push([:slim, :interpolate, txt.prepend(?\n)])
      end
    end
    parser.build [:html, :comment, [:slim, :text, out]]
    true
  end
end
end
