module Slim
module TagClosed
  extend self

  def try(parser, scanner, tags)

    unless txt = scanner.scan(%r~\s*/~)
      return false
    end

    # do nothing

    scanner.eol?
  end
end
end
