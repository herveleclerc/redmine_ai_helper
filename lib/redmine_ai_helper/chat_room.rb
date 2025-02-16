require "redmine_ai_helper/logger"

module RedmineAiHelper
  class ChatRoom
    include RedmineAiHelper::Logger
    attr_accessor :agents, :messages

    def initialize(goal)
      @agents = []
      @goal = goal
      first_message =<<~EOS
        ユーザーのゴールは以下です。各エージェントで協力して、このゴールを達成してください。
        ----
        goal:
        #{goal}
      EOS
      add_message("leader", first_message)
      ai_helper_logger.info "#{@messages.first}"
    end

    def goal
      @goal
    end

    def add_agent(agent)
      @agents << agent
    end

    def add_message(role, message)
      @messages ||= []
      @messages << { role: "assistant", content: "role: #{role}\n----\n#{message}" }
    end

    def get_agent(role)
      @agents.find { |agent| agent.role == role }
    end

    # Send a message from one agent to another. The message is saved in the messages.
    # @param [String] from the role of the agent sending the message
    # @param [String] to the role of the agent receiving the message
    def send_message(from, to, message, option = {}, proc = nil)
      add_message(from, message)
      agent = get_agent(to)
      answer = agent.chat(@messages, option, proc)
      add_message(to, answer)
      answer
    end

    # Send a task from one agent to another. The task is saved in the messages.
    # @param [String] from the role of the agent sending the task
    # @param [String] to the role of the agent receiving the task
    def send_task(from, to, task, option = {}, proc = nil)
      add_message(from, task)
      ai_helper_logger.info @messages.last
      agent = get_agent(to)
      unless agent
        error = "Agent not found: #{to}"
        ai_helper_logger.error error
        raise error
      end
      answer = agent.perform_task(@messages, option, proc)
      add_message(to, answer)
      ai_helper_logger.info @messages.last
      answer
    end
  end
end
