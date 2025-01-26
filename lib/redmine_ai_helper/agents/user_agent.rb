require "redmine_ai_helper/base_agent"

module RedmineAiHelper
  module Agents
    class UserAgent < RedmineAiHelper::BaseAgent
      RedmineAiHelper::BaseAgent.add_agent(name: "user_agent", class: self)
      def self.list_tools()
        list = {
          tools: [
            {
              name: "list_users",
              description: "Returns a list of all users who have logged in within the past year. Since the assignee or creator of a ticket may not necessarily be a project member, it is necessary to search for user IDs not only from project members but also from here.",
              arguments: {},
            },
          ],
        }
        list
      end

      # Returns a list of all users who have logged in within the past year
      def list_users(args = {})
        users = User.where("last_login_on >= ?", 1.year.ago)
        users.map do |user|
          {
            id: user.id,
            login: user.login,
            firstname: user.firstname,
            lastname: user.lastname,
          }
        end
      end
    end
  end
end
