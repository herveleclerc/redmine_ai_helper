require "redmine_ai_helper/logger"

module RedmineAiHelper
  class ChatRoom
    include RedmineAiHelper::Logger
    attr_accessor :agents, :messages

    def initialize(goal)
      @agents = []
      @goal = goal
      first_message =<<~EOS
        ユーザーのゴールは「#{goal}」です。各エージェントで協力して、このゴールを達成してください。
      EOS
      @messages = [{ role: "leader", content: first_message }]
      ai_helper_logger.info "#{@messages.first}"
    end

    def goal
      @goal
    end

    def add_agent(agent)
      @agents << agent
    end

    def add_message(message)
      @messages << message
    end

    def get_agent(role)
      @agents.find { |agent| agent.role == role }
    end

    # Send a message from one agent to another. The message is saved in the messages.
    # @param [String] from the role of the agent sending the message
    # @param [String] to the role of the agent receiving the message
    def send_message(from, to, message, option = {}, proc = nil)
      @messages << {
        role: from,
        content: message,
      }

      agent = get_agent(to)
      answer = agent.chat(@messages, option, proc)
      @messages << {
        role: to,
        content: answer,
      }
      answer
    end

    # Send a task from one agent to another. The task is saved in the messages.
    # @param [String] from the role of the agent sending the task
    # @param [String] to the role of the agent receiving the task
    def send_task(from, to, task, option = {}, proc = nil)
      @messages << { role: from, content: task }
      ai_helper_logger.info @messages.last
      messages_for_ai = @messages.map do |message|
        {
          role: "assistant",
          content: "role: #{message[:role]}\n----\n#{message[:content]}",
        }
      end
      agent = get_agent(to)
      answer = agent.perform_task(messages_for_ai, option, proc)
      @messages << { role: to, content: answer }
      ai_helper_logger.info @messages.last
      answer
    end
  end
end
