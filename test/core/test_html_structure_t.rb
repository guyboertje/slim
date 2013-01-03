require 'helper'

class TestSlimHtmlStructureT < TestSlim
  
  def test_output_block2
    source = %q{
p = hello_world "Hello Ruby" do
  = "Hello from block"
p Hello
= unknown_ruby_method
}

    assert_ruby_error NameError, "(__TEMPLATE__):5", source
  end

# ruby -I"lib:lib:test/core" test/core/test_html_structure_t.rb --seed 27793

end
