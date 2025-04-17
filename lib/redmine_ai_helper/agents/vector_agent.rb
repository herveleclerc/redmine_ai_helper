require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    class VectorAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのベクター検索エージェントです。Redmine のチケットを全部検索します。
          自然言語を使用した様々な問い合わせに答えることができます。
          チケットを検索するタスクが得意です
        EOS
        content
      end

      def available_tool_providers
        []
      end

      def perform_task(messages, option = {}, callback = nil)
        vector_db = RedmineAiHelper::Vector::IssueVectorDb.new(llm: client)
        question = messages.last[:content]
        response = vector_db.ask(question: question)
        response.chat_completion
      end
    end
  end
end
