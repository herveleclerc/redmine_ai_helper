require "redmine_ai_helper/base_agent"
require "redmine_ai_helper/agent_response"

module RedmineAiHelper
  module Agents
    class UserAgent < RedmineAiHelper::BaseAgent
      RedmineAiHelper::BaseAgent.add_agent(name: "user_agent", class: self)
      def self.list_tools()
        list = {
          tools: [
            {
              name: "list_users",
              description: "Returns a list of all users. Since the assignee or creator of a ticket may not necessarily be a project member, it is necessary to search for user IDs not only from project members but also from here.
              The user information includes the following items: id, login, firstname, lastname, created_on, last_login_on.",
              arguments: {},
            },
          ],
        }
        list
      end

      # Returns a list of all users who have logged in within the past year
      def list_users(args = {})
        users = User.active.where(type: "User")
        user_list = []
        users.map do |user|
          user_list <<
          {
            id: user.id,
            login: user.login,
            firstname: user.firstname,
            lastname: user.lastname,
            created_on: user.created_on,
            last_login_on: user.last_login_on,
          }
        end
        json = { users: user_list }
        AgentResponse.create_success json
      end
    end
  end
end
