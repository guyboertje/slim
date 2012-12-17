module Slim
module TagClosed
  extend self

  def try(parser, scanner, tags)

    unless txt = scanner.scan(%r~\s*/~)
      return false
    end

    # add nothing - consume to eol
    scanner.shift_text

    true
  end
end
end
