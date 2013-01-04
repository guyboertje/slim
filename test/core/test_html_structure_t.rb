require 'helper'

class TestSlimHtmlStructureT < TestSlim
  
  def test_embedded_erb
    source = %q{
erb:
  <%= 123 %>
  Hello from ERB!
  <%#
    comment block
  %>
  <% if true %>
  Text
  <% end %>
= unknown_ruby_method
}
    assert_ruby_error NameError,"(__TEMPLATE__):11", source
  end

# ruby -I"lib:lib:test/core" test/core/test_html_structure_t.rb --seed 27793

end
