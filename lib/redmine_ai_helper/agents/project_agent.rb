require "redmine_ai_helper/base_agent"

module RedmineAiHelper
  module Agents
    class ProjectAgent < RedmineAiHelper::BaseAgent
      RedmineAiHelper::BaseAgent.add_agent(name: "project_agent", class: self)
      def self.list_tools()
        list = {
          tools: [
            {
              name: "list_projects",
              description: "List all projects visible to the current user.",
              arguments: {},
            },
            {
              name: "read_project",
              description: "Read a project from the database and return it as a JSON object.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    id: "integer",
                    name: "string",
                    identifier: "string",
                  },
                  "anyOf": [
                    { required: ["id"] },
                    { required: ["name"] },
                    { required: ["identifier"] },
                  ],
                },
              },
            },
            {
              name: "project_members",
              description: "List all members of the project. It can be used to obtain the ID from the user's name. It can also be used to obtain the roles that the user has in the project.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    project_id: "integer",
                  },
                  required: ["project_id"],
                },
              },
            },
            {
              name: "project_enabled_modules",
              description: "List all enabled modules of the project. It shows the functions and plugins enabled in this project.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    project_id: "integer",
                  },
                  required: ["project_id"],
                },
              },
            },
            {
              name: "list_project_activities",
              description: "List all activities of the project.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    project_id: "integer",
                    author_id: {
                      type: "integer",
                      description: "The user ID of the author of the activity. If not specified, it will return all activities.",
                    },
                    limit: {
                      type: "integer",
                      description: "The maximum number of activities to return. If not specified, it will return all activities.",
                      default: 100,
                    },
                    start_date: {
                      type: "string",
                      format: "date",
                      description: "The start date of the activities to return.",
                      default: "30 Days Ago",
                    },
                    end_date: {
                      type: "string",
                      format: "date",
                      description: "The end date of the activities to return. If not specified, it will return all activities.",
                    },
                    required: ["project_id"],
                  }
                },
              },
            }
          ],
        }
        list
      end

      # List all projects visible to the current user.
      def list_projects(args = {})
        projects = Project.all
        projects.select { |p| p.visible? }.map do |project|
          {
            id: project.id,
            name: project.name,
            identifier: project.identifier,
            description: project.description,
            created_on: project.created_on,
            last_activity_date: project.last_activity_date,
          }
        end
        AgentResponse.create_success(projects)
      end

      # Read a project from the database and return it as a JSON object.
      def read_project(args = {})
        sym_args = args.deep_symbolize_keys
        project_id = sym_args[:id]
        project_name = sym_args[:name]
        project_identifier = sym_args[:identifier]
        project = nil
        if project_id
          project = Project.find(project_id)
        elsif project_name
          project = Project.find_by(name: project_name)
        elsif project_identifier
          project = Project.find_by(identifier: project_identifier)
        else
          return AgentResponse.create_error "No id or name or Identifier specified."
        end

        return AgentResponse.create_error "Project not found" unless project
        return AgentResponse.create_error "You don't have permission to view this project" unless project.visible?
        project_json = {
          id: project.id,
          name: project.name,
          identifier: project.identifier,
          description: project.description,
          homepage: project.homepage,
          status: project.status,
          is_public: project.is_public,
          inherit_members: project.inherit_members,
          created_on: project.created_on,
          updated_on: project.updated_on,
          subprojects: project.children.select { |p| p.visible? }.map do |child|
            {
              id: child.id,
              name: child.name,
              identifier: child.identifier,
              description: child.description,
            }
          end,
          last_activity_date: project.last_activity_date,
        }
        AgentResponse.create_success project_json
      end

      # List all members of the project.
      def project_members(args = {})
        sym_args = args.deep_symbolize_keys
        project_id = sym_args[:project_id]
        project = Project.find(project_id)
        return AgentResponse.create_error "Project not found" unless project
        return AgentResponse.create_error "You don't have permission to view this project" unless project.visible?

        members = project.members.map do |member|
          {
            user_id: member.user_id,
            login: member.user.login,
            user_name: member.user.name,
            roles: member.roles.map do |role|
              {
                id: role.id,
                name: role.name,
              }
            end,
          }
        end
        json = {
          project_id: project_id,
          members: members,
        }
        AgentResponse.create_success json
      end

      # List all modules of the project.
      # It shows the functions and plugins enabled in this project.
      def project_enabled_modules(args = {})
        sym_args = args.deep_symbolize_keys
        project_id = sym_args[:project_id]
        project = Project.find(project_id)
        return AgentResponse.create_error "Project not found" unless project
        return AgentResponse.create_error "You don't have permission to view this project" unless project.visible?

        enabled_modules = project.enabled_modules.map do |enabled_module|
          {
            name: enabled_module.name,
          }
        end
        json = {
          project_id: project_id,
          enabled_modules: enabled_modules,
        }
        AgentResponse.create_success json
      end

      # List all activities of the project.
      def list_project_activities(args = {})
        sym_args = args.deep_symbolize_keys
        project_id = sym_args[:project_id]
        project = Project.find(project_id)
        return AgentResponse.create_error "Project not found" unless project
        return AgentResponse.create_error "You don't have permission to view this project" unless project.visible?

        author_id = sym_args[:author_id]
        author = author_id ? User.find(author_id) : nil
        limit = sym_args[:limit] || 100
        start_date = sym_args[:start_date] || 30.days.ago
        end_date = sym_args[:end_date] || 1.day.from_now

        current_user = User.current
        fetcher = Redmine::Activity::Fetcher.new(
          current_user, 
          project: project,
          author: author,
        )
        ai_helper_logger.info "current_user: #{current_user}, project: #{project}, author: #{author}, start_date: #{start_date}, end_date: #{end_date}, limit: #{limit}"
        events = fetcher.events(start_date, end_date).sort_by(&:event_datetime).reverse.first(limit)
        # events = fetcher.events(start_date, end_date, limit).sort_by(&:event_datetime)
        # events = fetcher.events(start_date)
        list = []
        events.each do |event|
          list << {
            id: event.id,
            event_datetime: event.event_datetime,
            event_type: event.event_type,
            event_title: event.event_title,
            event_description: event.event_description,
            event_url: event.event_url,
          }
        end
        json = {"activities": list}
        AgentResponse.create_success json
      end
    end
  end
end
