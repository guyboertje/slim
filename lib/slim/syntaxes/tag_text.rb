module Slim
module TagText
  extend self

  def try(parser, scanner, tags)

    unless tag_txt = scanner.scan(%r{ ?.*(?=\r?\n)})
      return true
    end

    ap from: "TagText", tag_line: tag_txt

    out = [:multi, [:slim, :interpolate, tag_txt.lstrip]]

    tags.push [:slim, :text, out]

    true
  end
end
end
