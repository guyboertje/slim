require 'helper'

class TestSlimHtmlStructureT < TestSlim


  def test_boolean_attribute_shortcut
    source = %{
option(class="clazz" selected) Text
option(selected class="clazz") Text
}

    assert_html '<option class="clazz" selected="selected">Text</option><option class="clazz" selected="selected">Text</option>', source
  end

# ruby -I"lib:lib:test/core" test/core/test_html_structure.rb --seed 27793

end
