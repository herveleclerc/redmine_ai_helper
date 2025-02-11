require "redmine_ai_helper/base_tool_provider"

module RedmineAiHelper
  module ToolProviders
    class VersionToolProvider < RedmineAiHelper::BaseToolProvider
      def self.list_tools()
        list = {
          tools: [
            {
              name: "list_versions",
              description: "List all versions in the project. It returns the version ID, name, description, status, due_date, sharing, wiki_page_title, and created_on.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    project_id: {
                      type: "integer"
                    },
                  },
                  required: ["project_id"],
                },
              },
            },
            {
              name: "version_info",
              description: "Read a version from the database and return it as a JSON object. It returns the version ID, project ID, name, description, status, due_date, sharing, wiki_page_title, and created_on, estimated_hours, spent_hours, and issues.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    version_id: {
                      type: "integer"
                    },
                  },
                  required: ["version_id"],
                },
              },
            }
          ]
        }
        list
      end

      # List all versions in the project.
      # args: { project_id: "integer" }
      def list_versions(args = {})
        sym_args = args.deep_symbolize_keys
        project_id = sym_args[:project_id]
        return ToolResponse.create_error("Project ID is required.") if project_id.nil?
        project = Project.find_by_id(project_id)
        return ToolResponse.create_error("Project not found") if project.nil? or !project.visible?
        versions = project.versions.filter(&:visible?)
        version_list = versions.map do |version|
          {
            id: version.id,
            name: version.name,
            description: version.description,
            status: version.status,
            due_date: version.due_date,
            sharing: version.sharing,
            wiki_page_title: version.wiki_page_title,
            created_on: version.created_on,
            url_for_version: "#{version_url(version, only_path: true)}",
          }
        end

        ToolResponse.create_success(version_list)
      end

      # Read a version from the database and return it as a JSON object.
      # args: { version_id: "integer" }
      def version_info(args = {})
        sym_args = args.deep_symbolize_keys
        version_id = sym_args[:version_id]
        return ToolResponse.create_error("Version ID is required.") if version_id.nil?
        version = Version.find_by_id(version_id)
        return ToolResponse.create_error("Version not found") if version.nil? or !version.visible?
        version_hash = {
          id: version.id,
          project_id: version.project_id,
          name: version.name,
          description: version.description,
          status: version.status,
          due_date: version.due_date,
          sharing: version.sharing,
          wiki_page_title: version.wiki_page_title,
          created_on: version.created_on,
          estimated_hours: version.estimated_hours,
          spent_hours: version.spent_hours,
          url_for_version: "#{version_url(version, only_path: true)}",
          issues: version.fixed_issues.filter(&:visible?).map do |issue|
            {
              id: issue.id,
              subject: issue.subject,
              status: issue.status,
              priority: issue.priority,
              url_for_issue: "#{issue_url(issue, only_path: true)}",
            }
          end
        }
        ToolResponse.create_success(version_hash)
      end
    end
  end
end
