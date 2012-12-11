module Slim
module TagShortcutAttributes
  extend self

  def try(parser, scanner, attributes)

    shortcut_part = parser.shortcut.keys.join.prepend('[').concat(']')
    sc_re = %r~(#{shortcut_part}\w[\w-]*\w)+~
    if scs = scanner.scan(sc_re)
      ap from: "TagShortcutAttributes: shortcuts", found: scs
      scs.scan(%r{(#{shortcut_part})(\w[\w-]*\w)}).each do |dot, val|
        sub = parser.shortcut_lookup(dot)
        attributes.push [:html, :attr, sub, [:static, val]]
      end
    end
    scanner.eol?
  end
end
end
