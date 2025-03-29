require "redmine_ai_helper/base_agent"
require "redmine_ai_helper/util/system_prompt"
require "redmine_ai_helper/util/json_extractor"

module RedmineAiHelper
  module Agents
    class LeaderAgent < RedmineAiHelper::BaseAgent
      def initialize(params = {})
        super(params)
        @system_prompt = RedmineAiHelper::Util::SystemPrompt.new(params)
      end
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのリーダーエージェントです。他のエージェントに指示を出し、彼らが答えた内容をまとめ、最終回答をユーザーに返すことがあなたの役割です。
          また、他のエージェントが実行できないタスクの場合には、自らタスクを実行することもあります。
        EOS
        content
      end

      def role
        "leader"
      end

      def system_prompt
        {
          role: "system",
          content: @system_prompt.prompt + "\n----\n" + backstory,
        }
      end

      def perform_task(messages, option = {}, callback = nil)

        goal = generate_goal(messages)
        ai_helper_logger.debug "goal: #{goal}"
        steps = generate_steps(goal, messages)
        ai_helper_logger.debug "steps: #{steps}"

        if steps["steps"].empty? || steps["steps"].length == 1 && steps["steps"][0]["agent"] == "leader"
          return chat(messages, option, callback)
        end

        chat_room = RedmineAiHelper::ChatRoom.new(goal)
        agent_list = RedmineAiHelper::AgentList.instance
        steps["steps"].map{ |step| step["agent"] }.uniq.reject{|a| a == "leader_agent" }.each do |agent|
          agent_instance = agent_list.get_agent_instance(agent, {project: @project})
          chat_room.add_agent(agent_instance)
        end

        steps["steps"].each do |step|
          chat_room.send_task("leader", step["agent"], step["step"])
        end

        newmessages = messages + chat_room.messages
        newmessages << { role: "system", content: "全てのエージェントのタスクが完了しました。最終的なユーザーへの回答を作成してください。" }
        ai_helper_logger.debug "newmessages: #{newmessages}"
        chat(newmessages, option, callback)
      end

      def generate_goal(messages)
        prompt = load_prompt("leader_agent/goal")

        newmessages = messages.dup
        newmessages << { role: "system", content: prompt.format }
        answer = chat(newmessages)
        answer
      end

      def generate_steps(goal, messages)
        agent_list = RedmineAiHelper::AgentList.instance
        ai_helper_logger.debug "agent_list: #{agent_list.list_agents}"
        prompt = <<~EOS
          「#{goal}」というゴールを解決するために、他のエージェントに指示を出してください。
          各ステップでは、前のステップの実行で得られた結果をどのように利用するかを考慮してください。
          エージェントの backstory を考慮して、適切なエージェントを選択してください。
          適切なエージェントが見つからない場合には、"leader" に指示を出してください。
          エージェントへの指示は、JSON形式で記述してください。

          ** ユーザーへの確認を行うゴールが設定されている場合には、他のエージェントに対してデータを作成したり更新したりする指示を出してはいけません。その場合には他のエージェントには情報を取得する依頼のみ行うことができます。 **

          ** 回答にはJSON以外を含めないでください。解説等は不要です。 **
          ----
          エージェントの一覧:
          #{agent_list.list_agents.reject{|a| a[:agent_name] == "leader_agent"}}
          ----
          JSONスキーマ:
          {
            type: "object",
            properties: {
              steps: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    agent: {
                      type: "string",
                      description: "指示を出すエージェントのロール"
                    },
                    step: {
                      type: "string",
                      description: "指示内容"
                    }
                  },
                  required: ["agent", "step"]
                }
              }
            }
          }
          ----
          適切なエージェントが見つかった場合のJSONの例:
          {
            "steps": [
              {
                "agent": "project_agent",
                "step": "my_projectという名前のプロジェクトのIDを教えてください"
              },
              {
                "agent": "issue_agent",
                "step": "前のステップで取得したプロジェクトのIDに関連するチケットを教えてください"
              }
            ]
          }
          ----
          適切なエージェントが見つからなかった場合のJSONの例:
          {
            "steps": [
              {
                "agent": "leader",
                "step": "「こんにちは」という挨拶に対して返答を作成してください"
              }
            ]
          }
        EOS

        newmessages = messages.dup
        newmessages << { role: "system", content: prompt }
        json = chat(newmessages)
        RedmineAiHelper::Util::JsonExtractor.extract(json)
      end

    end
  end
end
