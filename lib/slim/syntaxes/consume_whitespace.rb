module Slim
module ConsumeWhitespace
  extend self
  def try(parser, scanner, current_indent)
    # ap "blank_lines"
    if lines = scanner.shift_until_char
      # ap from: "ConsumeWhitespace", lines: lines
      lines.count(?\n).times do
        scanner.liner.inc
        parser.build [:newline]
      end
      scanner.indentation lines[/ *\z/]
      true
    else
      while scanner.shift_lf do
        scanner.liner.inc
        parser.build [:newline]
      end
      false
    end
  end
end
end
