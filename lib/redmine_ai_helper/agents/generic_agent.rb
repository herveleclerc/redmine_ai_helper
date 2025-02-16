require_relative '../base_agent'
module RedmineAiHelper
  module Agents
    class GenericAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインの汎用エージェントです。このRedmine に関する問い合わせで、他のエージェントでは答えられない雑多な質問に答えます。
        EOS
        content
      end

    end
  end
end
