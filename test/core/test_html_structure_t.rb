require 'helper'

class TestSlimHtmlStructure < TestSlim


  def test_attributs_with_parens_and_spaces
    source = %q{label{ for='filter' }= hello_world}
    assert_html '<label for="filter">Hello World from @env</label>', source
  end

# ruby -I"lib:lib:test/core" test/core/test_html_structure.rb --seed 27793

end
