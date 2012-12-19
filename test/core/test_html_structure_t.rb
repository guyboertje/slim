require 'helper'

class TestSlimHtmlStructureT < TestSlim

  def test_invalid_empty_attribute2
    source = %q{
p
  img{src=}
}

    assert_syntax_error "Invalid empty attribute\n  (__TEMPLATE__), Line 3, Column 10\n    img{src=}\n            ^\n", source
  end

# ruby -I"lib:lib:test/core" test/core/test_html_structure.rb --seed 27793

end
