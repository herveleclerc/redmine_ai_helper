require_relative '../base_agent'
module RedmineAiHelper
  module Agents
    class UserAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのユーザーエージェントです。Redmine のユーザーに関する問い合わせに答えます。

          Redmineでチケットやwikiページなどをユーザーをキーに検索する場合にはユーザー名ではなくユーザーIDを使うことが多いです。
          よって他のエージェントのためにユーザIDを検索してあげることもあります。
        EOS
        content
      end

      def available_tool_providers
        ["user_tool_provider"]
      end
    end
  end
end
