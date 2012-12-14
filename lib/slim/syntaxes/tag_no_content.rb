module Slim
module TagNoContent
  extend self

  def try(parser, scanner, tags)

    unless txt = scanner.scan(%r~\s*(?=\r?\n)~)
      return false
    end

    content = [:multi]
    tags.push content
    parser.push content

    true
  end
end
end
