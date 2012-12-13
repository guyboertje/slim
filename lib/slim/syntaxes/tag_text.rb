module Slim
module TagText
  extend self

  def try(parser, scanner, tags)
    unless scanner.scan(%r{ ?(.*)(?=\r?\n)})
      scanner.scan_until(/(?=\r?\n)/)
      return true
    end

    tag_txt = scanner.m1

    ap "TagText:>" + tag_txt

    out = [:multi, [:slim, :interpolate, tag_txt]]

    tags.push [:slim, :text, out]

    true
  end
end
end
# .lstrip
