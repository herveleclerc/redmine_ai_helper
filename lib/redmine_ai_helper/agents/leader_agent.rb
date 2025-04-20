# frozen_string_literal: true
require "redmine_ai_helper/base_agent"
require "redmine_ai_helper/util/system_prompt"

module RedmineAiHelper
  module Agents
    # LeaderAgent is an agent responsible for giving instructions to other agents,
    # summarizing their responses, and providing the final answer to the user.
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

      # Perform a user request by generating a goal and steps for the agents to follow.
      def perform_user_request(messages, option = {}, callback = nil)
        goal = generate_goal(messages)
        ai_helper_logger.info "goal: #{goal}"
        steps = generate_steps(goal, messages)
        ai_helper_logger.info "steps: #{steps}"

        if steps["steps"].empty? || steps["steps"].length == 1 && steps["steps"][0]["agent"] == "leader"
          return chat(messages, option, callback)
        end

        chat_room = RedmineAiHelper::ChatRoom.new(goal)
        agent_list = RedmineAiHelper::AgentList.instance
        steps["steps"].map { |step| step["agent"] }.uniq.reject { |a| a == "leader_agent" }.each do |agent|
          agent_instance = agent_list.get_agent_instance(agent, { project: @project })
          chat_room.add_agent(agent_instance)
        end

        steps["steps"].each do |step|
          chat_room.send_task("leader", step["agent"], step["step"])
        end

        newmessages = messages + chat_room.messages
        # TODO: 英語にする
        newmessages << { role: "user", content: "全てのエージェントのタスクが完了しました。最終的なユーザーへの回答を作成してください。" }
        ai_helper_logger.debug "newmessages: #{newmessages}"
        chat(newmessages, option, callback)
      end

      # Generate a goal for the agents to follow based on the user's request.
      def generate_goal(messages)
        prompt = load_prompt("leader_agent/goal")

        newmessages = messages.dup
        newmessages << { role: "user", content: prompt.format }
        answer = chat(newmessages)
        answer
      end

      # Generate steps for the agents to follow based on the goal.
      def generate_steps(goal, messages)
        agent_list = RedmineAiHelper::AgentList.instance
        ai_helper_logger.debug "agent_list: #{agent_list.list_agents}"
        agent_list_string = agent_list.list_agents.reject { |a| a[:agent_name] == "leader_agent" }
        prompt = load_prompt("leader_agent/generate_steps")
        json_schema = {
          type: "object",
          properties: {
            steps: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  agent: {
                    type: "string",
                    description: "指示を出すエージェントのロール", # TODO: 英語にする
                  },
                  step: {
                    type: "string",
                    description: "指示内容", # TODO: 英語にする
                  },
                },
                required: ["agent", "step"],
              },
            },
          },
        }
        parser = Langchain::OutputParsers::StructuredOutputParser.from_json_schema(json_schema)
        # TODO: 英語にする
        json_examples = <<~EOS
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

        prompt_text = prompt.format(
          goal: goal,
          agent_list: agent_list_string,
          format_instructions: parser.get_format_instructions,
          json_examples: json_examples,
        )

        ai_helper_logger.info "prompt_text: #{prompt_text}"

        newmessages = messages.dup
        newmessages << { role: "user", content: prompt_text }
        json = chat(newmessages)
        fix_parser = Langchain::OutputParsers::OutputFixingParser.from_llm(
          llm: client,
          parser: parser,
        )
        fix_parser.parse(json)
      end
    end
  end
end
