module Slim
module EmbeddedTemplate
  extend self

  def try(parser, scanner)
    current_indent = scanner.current_indent
    unless embedded_line = scanner.scan(%r{(\w+):(?=\r?\n)})
      return false
    end
    
    out = [:multi]
    min_indent = current_indent.succ
    engine = scanner.m1

    if block = scanner.shift_indented_lines(min_indent)
      margin, pre = nil, ""
      lines = block.split(/\r?\n/)
      scanner.liner.inc
      lines.shift
      lines.each do |line|
        len = line.size
        if margin.nil? && (ind = line[/\A */].size) > 0
          margin = ind
        end
        txt = line.slice(margin || len, len)
        out.push [:newline]
        out.push([:slim, :interpolate, txt.prepend(pre)]) unless txt.empty?
        pre = ?\n if margin && pre.empty?
      end
    end
    parser.build [:slim, :embedded, engine, out]
    true
  end
end
end
