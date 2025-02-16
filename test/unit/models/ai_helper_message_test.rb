require File.expand_path("../../../test_helper", __FILE__)

class AiHelperMessageTest < ActiveSupport::TestCase
  def setup
    @message = AiHelperMessage.new
  end

  def test_message_initialization
    assert_not_nil @message
  end
end
