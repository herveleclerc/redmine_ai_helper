require File.expand_path("../../../test_helper", __FILE__)

class SystemToolProviderTest < ActiveSupport::TestCase
  def setup
    @provider = RedmineAiHelper::Tools::SystemToolProvider.new
  end

  def test_list_plugins
    response = @provider.list_plugins

    assert response.content[:plugins].any?
  end
end
