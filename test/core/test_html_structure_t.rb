require 'helper'

class TestSlimHtmlStructureT < TestSlim


  def test_splat_with_other_attributes
    source = %q{
h1 data-id="123" *hash This is my title
}

    assert_html '<h1 a="The letter a" b="The letter b" data-id="123">This is my title</h1>', source
  end

# ruby -I"lib:lib:test/core" test/core/test_html_structure_t.rb --seed 27793

end
