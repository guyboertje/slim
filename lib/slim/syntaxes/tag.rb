module Slim
module Tag
  extend self

  def try(parser, scanner, tag_re, shortcut_re, tags, attributes, memo)
    memo[:tag_indent] = scanner.current_indent
    memo[:tag_position] = scanner.position

    tag = if sc = scanner.check(shortcut_re)
            parser.shortcut_sub(sc)
          else
            scanner.scan(tag_re)
          end

    unless tag
      # raise "should be a tag, all other options tried"
      return true
    end
    
    # ap "Tag:>#{tag}"

    tags.concat [:html, :tag, tag]

    false
  end
end
end
