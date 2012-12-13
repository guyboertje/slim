module Slim
module TagNoContent
  extend self

  def try(parser, scanner, tags)

    unless txt = scanner.scan(%r~\s*(?=\r?\n)~)
      return false
    end
    ap "TagNoContent"

    content = [:multi]
    tags.push content
    parser.push content

    true
  end
end
end
