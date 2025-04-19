require File.expand_path("../../../test_helper", __FILE__)

class SystemToolsTest < ActiveSupport::TestCase
  def setup
    @provider = RedmineAiHelper::Tools::SystemTools.new
  end

  def test_list_plugins
    response = @provider.list_plugins

    assert response[:plugins].any?
  end
end
