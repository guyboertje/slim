module Slim
module TagBooleanAttributes
  extend self

  def try(parser, scanner, attributes, wrapped_attributes)
    return false unless wrapped_attributes
    return false unless atbe = scanner.scan(%r~\s*(\w[:\w-]*)(?=\s|\r?\n)~)

    attributes.push [:html, :attr, atbe.strip, [:slim, :attrvalue, false, 'true']]
    true
  end
end
end
