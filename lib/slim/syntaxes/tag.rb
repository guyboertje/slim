module Slim
module Tag
  extend self

  def try(parser, scanner, tag_re, shortcut_re, tags)

    tag = if sc = scanner.check(shortcut_re)
            parser.shortcut_sub(sc)
          else
            scanner.scan(tag_re)
          end

    unless tag
      # raise "should be a tag, all other options tried"
      return true
    end
    
    ap from: "Tag", tag: tag

    tags.concat [:html, :tag, tag]

    scanner.eol?
  end
end
end
