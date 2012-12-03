module Slim
module Tag
  extend self

  def try(parser, scanner, tag_re)
    unless tag_line = scanner.scan(tag_re)
      return false
    end
    

    tag = scanner.m1
    sub = parser.shortcut_sub(tag)
    rest = scanner.m3
    ap from: "Tag", tag_line: tag_line, tag: tag, rest: scanner.m3

    attributes = [:html, :attrs]
    rest = parse_attributes(parser, scanner, rest, attributes)
    out = [:html, :tag, tag, attributes]
    parser.build out



    true
  end

  def parse_attributes(parser, scanner, rest, attributes)
    attributes = [:html, :attrs]
    


    attributes
  end
end
end
