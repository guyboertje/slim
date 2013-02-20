require 'helper'

class TestSlimCodeBlocks < TestSlim
  def test_render_with_output_code_block
    source = %q{
p.red sixty
+ Env.inlined_slim
p.green testing
}

    assert_html '<p class="red">sixty</p><p class="blue"></p><p class="green">testing</p>', source
  end

end
