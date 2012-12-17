module Slim
module ConsumeWhitespace
  extend self
  def try(parser, scanner, current_indent)
    if lines = scanner.shift_until_char
      lines.count(?\n).times do
        scanner.liner.inc
        parser.last_push [:newline]
      end
      scanner.indentation lines[/ *\z/]
      true
    else
      while scanner.shift_lf do
        scanner.liner.inc
        parser.last_push [:newline]
      end
      false
    end
  end
end
end
