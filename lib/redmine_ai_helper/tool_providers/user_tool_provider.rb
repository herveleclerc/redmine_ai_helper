require "redmine_ai_helper/base_tool_provider"
require "redmine_ai_helper/agent_response"

module RedmineAiHelper
  module ToolProviders
    class UserToolProvider < RedmineAiHelper::BaseToolProvider
      def self.list_tools()
        list = {
          tools: [
            {
              name: "list_users",
              description: "Returns a list of all users. Since the assignee or creator of a ticket may not necessarily be a project member, it is necessary to search for user IDs not only from project members but also from here.
              The user information includes the following items: id, login, firstname, lastname, created_on, last_login_on.",
              arguments: {
                query: {
                  type: "object",
                  properties: {
                    limit: {
                      type: "integer",
                      description: "The maximum number of users to return. The default is 100.",
                      default: 100,
                    },
                    status: {
                      type: "string",
                      enum: ["active", "locked", "registered"],
                      description: "The status of the users to return. The default is 'active'.",
                      default: "active",
                    },
                    date_fields: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          field_name: {
                            type: "string",
                            enum: ["created_on", "last_login_on"],
                            description: "The date field to filter on.",
                          },
                          operator: {
                            type: "string",
                            enum: ["=", "!=", ">", "<", ">=", "<="],
                            description: "The operator to use for the filter.",
                          },
                          value: {
                            type: "string",
                            description: "The value to filter on.",
                          },
                          required: ["field_name", "operator", "value"],
                        },
                      },
                      description: "The date fields to filter on.",
                    },
                    sort: {
                      type: "object",
                      properties: {
                        field_name: {
                          type: "string",
                          enum: ["id", "login", "firstname", "lastname", "created_on", "last_login_on"],
                          description: "The field to sort on.",
                          default: "last_login_on",
                        },
                        order: {
                          type: "string",
                          enum: ["asc", "desc"],
                          description: "The order to sort in.",
                          default: "desc",
                        },
                        required: ["field_name", "order"],
                      },
                      description: "The field to sort on.",
                    },
                  },
                },
              },
            },
          ],
        }
        list
      end

      # Returns a list of all users who have logged in within the past year
      def list_users(args = {})
        sym_args = args.deep_symbolize_keys
        query = sym_args[:query] || {}
        limit = query[:limit] || 100
        status = query[:status] || "active"
        status_value = { "active" => 1, "registered" => 2, "locked" => 3 }
        date_fields = query[:date_fields] || []
        sort = query[:sort] || { field_name: "last_login_on", order: "desc" }

        users = User.where(type: "User").where(status: status_value[status]).order(sort[:field_name] => sort[:order])

        date_fields.each do |date_field|
          field_name = date_field[:field_name]
          operator = date_field[:operator]
          value = date_field[:value]
          if ["<", "<="].include?(operator)
            users = users.where("#{field_name} #{operator} ? OR #{field_name} IS NULL", value)
          else
            users = users.where("#{field_name} #{operator} ?", value)
          end
        end

        count = users.count
        users = users.limit(limit)
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
        json = { users: user_list, total: count }
        AgentResponse.create_success json
      end
    end
  end
end
