require "redmine_ai_helper/base_tool_provider"

module RedmineAiHelper
  module Tools
    class ProjectToolProvider < RedmineAiHelper::BaseToolProvider

      define_function :list_projects, description: "List all projects visible to the current user. It returns the project ID, name, identifier, description, created_on, and last_activity_date." do
        property :dummy, type: "string", description: "dummy property", required: false
      end

      # List all projects visible to the current user.
      def list_projects(dummy: nil)
        projects = Project.all
        list = projects.select { |p| accessible_project? p }.map do |project|
          {
            id: project.id,
            name: project.name,
            identifier: project.identifier,
            description: project.description,
            created_on: project.created_on,
            last_activity_date: project.last_activity_date,
          }
        end
        tool_response(content: list)
      end

      define_function :read_project, description: "Read a project from the database and return it as a JSON object. It returns the project ID, name, identifier, description, homepage, status, is_public, inherit_members, created_on, updated_on, subprojects, and last_activity_date." do
        property :project_id, type: "integer", description: "The project ID of the project to return.", required: false
        property :project_name, type: "string", description: "The project name of the project to return.", required: false
        property :project_identifier, type: "string", description: "The project identifier of the project to return.", required: false
      end

      # Read a project from the database.
      def read_project(project_id: nil, project_name: nil, project_identifier: nil)

        if project_id
          project = Project.find_by(id: project_id)
        elsif project_name
          project = Project.find_by(name: project_name)
        elsif project_identifier
          project = Project.find_by(identifier: project_identifier)
        else
          raise "No id or name or Identifier specified."
        end

        raise "Project not found" unless project
        raise "You don't have permission to view this project" unless accessible_project? project
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
          subprojects: project.children.select { |p| accessible_project? p }.map do |child|
            {
              id: child.id,
              name: child.name,
              identifier: child.identifier,
              description: child.description,
            }
          end,
          last_activity_date: project.last_activity_date,
        }
        tool_response(content: project_json)
      end

      define_function :project_members, description: "List all members of the projects. It can be used to obtain the ID from the user's name. It can also be used to obtain the roles that the user has in the projects. Member information includes user_id, login, user_name, and roles." do
        property :project_ids, type: "array", description: "The project IDs of the projects to return.", required: true do
          item type: "integer"
        end
      end

      # List all members of the project.
      def project_members(project_ids:)

        projects = Project.where(id: project_ids)
        return ToolResponse.create_error "No projects found" if projects.empty?

        list = projects.filter{|p| accessible_project? p }.map do |project|
          return ToolResponse.create_error "You don't have permission to view this project" unless accessible_project? project

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
          {
            project_id: project.id,
            project_name: project.name,
            members: members,
          }
        end
        tool_response(content: {projects: list})
      end

      define_function :project_enabled_modules, description: "List all enabled modules of the projects. It shows the functions and plugins enabled in this projects." do
        property :project_id, type: "integer", description: "The project ID of the project to return.", required: true
      end

      # List all modules of the project.
      # It shows the functions and plugins enabled in this project.
      def project_enabled_modules(project_id:)
        project = Project.find(project_id)
        return ToolResponse.create_error "Project not found" unless project
        return ToolResponse.create_error "You don't have permission to view this project" unless accessible_project? project

        enabled_modules = project.enabled_modules.map do |enabled_module|
          {
            name: enabled_module.name,
          }
        end
        json = {
          project_id: project_id,
          enabled_modules: enabled_modules,
        }
        tool_response(content: json)
      end

      define_function :list_project_activities, description: "List all activities of the project. It returns the activity ID, event_datetime, event_type, event_title, event_description, and event_url." do
        property :project_id, type: "integer", description: "The project ID of the activities to return.", required: true
        property :author_id, type: "integer", description: "The user ID of the author of the activity. If not specified, it will return all activities.", required: false
        property :limit, type: "integer", description: "The maximum number of activities to return. If not specified, it will return all activities.", required: false
        property :start_date, type: "string", description: "The start date of the activities to return.", required: false
        property :end_date, type: "string", description: "The end date of the activities to return. If not specified, it will return all activities.", required: false
      end

      # List all activities of the project.
      def list_project_activities(project_id:, author_id: nil, limit: nil, start_date: nil, end_date: nil)
        project = Project.find(project_id)
        return ToolResponse.create_error "Project not found" unless project
        return ToolResponse.create_error "You don't have permission to view this project" unless accessible_project? project

        author = author_id ? User.find(author_id) : nil
        limit ||= 100
        start_date ||= 30.days.ago
        end_date ||= 1.day.from_now

        current_user = User.current
        fetcher = Redmine::Activity::Fetcher.new(
          current_user,
          project: project,
          author: author,
        )
        ai_helper_logger.debug "current_user: #{current_user}, project: #{project}, author: #{author}, start_date: #{start_date}, end_date: #{end_date}, limit: #{limit}"
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
        json = { "activities": list }
        ToolResponse.create_success json
      end
    end
  end
end
