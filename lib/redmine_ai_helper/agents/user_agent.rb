# frozen_string_literal: true
require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # UserAgent is a specialized agent for handling Redmine user-related queries.
    class UserAgent < RedmineAiHelper::BaseAgent
      def backstory
        # TODO: 英語にする
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのユーザーエージェントです。Redmine のユーザーに関する問い合わせに答えます。

          Redmineでチケットやwikiページなどをユーザーをキーに検索する場合にはユーザー名ではなくユーザーIDを使うことが多いです。
          よって他のエージェントのためにユーザIDを検索してあげることもあります。
        EOS
        content
      end

      def available_tool_providers
        [RedmineAiHelper::Tools::UserTools]
      end
    end
  end
end
