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
      add_message("leader", first_message, "all")
    end

    def goal
      @goal
    end

    def add_agent(agent)
      @agents << agent
    end

    def add_message(role, message, to)
      ai_helper_logger.info "role: #{role}\n @#{to}, #{message}"
      @messages ||= []
      @messages << { role: "assistant", content: "role: #{role}\n----\nTo: #{to}\n#{message}" }
    end

    def get_agent(role)
      @agents.find { |agent| agent.role == role }
    end

    # Send a task from one agent to another. The task is saved in the messages.
    # @param [String] from the role of the agent sending the task
    # @param [String] to the role of the agent receiving the task
    def send_task(from, to, task, option = {}, proc = nil)
      add_message(from, task, to)
      agent = get_agent(to)
      unless agent
        error = "Agent not found: #{to}"
        ai_helper_logger.error error
        raise error
      end
      answer = agent.perform_task(@messages, option, proc)
      add_message(to, answer, from)
      answer
    end
  end
end
