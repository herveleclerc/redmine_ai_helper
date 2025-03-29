require_relative '../base_agent'
module RedmineAiHelper
  module Agents
    class VersionAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのバージョンエージェントです。Redmine のプロジェクトのロードマップやバージョンに関する問い合わせに答えます。
        EOS
        content
      end

      def available_tool_providers
        [RedmineAiHelper::Tools::VersionToolProvider]
      end
    end
  end
end
