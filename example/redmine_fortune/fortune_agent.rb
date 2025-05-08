require "redmine_ai_helper/base_agent"
require_relative "./fortune_tools"

class FortuneAgent < RedmineAiHelper::BaseAgent
  def backstory
    "あなたは、Redmine AI Helperプラグインの占いエージェントです。あなたはRedmineのユーザーの運勢を占いうことができます。おみくじや星座占いを提供します。"
  end

  def available_tool_providers
    [FortuneTools]
  end
end
