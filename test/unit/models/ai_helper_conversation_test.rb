require File.expand_path("../../../test_helper", __FILE__)

class AiHelperConversationTest < ActiveSupport::TestCase
  def setup
    @ai_helper = AiHelperConversation.new
  end


  def test_ai_helper_initialization
    assert_not_nil @ai_helper
  end
end
