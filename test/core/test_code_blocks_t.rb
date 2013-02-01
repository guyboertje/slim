require 'helper'

class TestSlimCodeBlocks < TestSlim
  def test_render_with_output_code_block
    source = %q{
p.red sixty
}

    assert_html '<p class="red">sixty</p>', source
  end


end
