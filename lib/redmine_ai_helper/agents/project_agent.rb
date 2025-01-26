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
        }
        AgentResponse.create_success project_json
      end

      # List all members of the project.
      def project_members(args = {})
        sym_args = args.deep_symbolize_keys
        project_id = sym_args[:project_id]
        project = Project.find(project_id)
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
    end
  end
end
