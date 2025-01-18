require "redmine_ai_helper/llm"

module RedmineAiHelper
  class Agent
    attr_accessor :llm

    def initialize(llm)
      @llm = llm
    end

    def self.listTools()
      list = {
        tools: [
          {
            name: "read_issue",
            description: "Read an issue from the database and return it as a JSON object.",
            arguments: {
              shema: {
                id: "integer",
              },
              required: ["id"],
            },
          },
          {
            name: "read_project",
            description: "Read a project from the database and return it as a JSON object.",
            arguments: {
              shema: {
                id: "integer",
              },
              required: ["id"],
            },
          },
        ],
      }
      list
    end

    def callTool(params = {})
      name = params[:name]
      args = params[:arguments]

      # Use reflection to call the method named 'name' on this instance, passing 'args' as arguments.
      # If the method does not exist, an exception will be raised.
      if respond_to?(name)
        send(name, args)
      else
        raise "Method #{name} not found"
      end
    end

    # Read an issue from the database and return it as a JSON object.
    # args: { id: issue_id }
    def read_issue(args = {})
      issue_id = args["id"]
      issue = Issue.find(issue_id)
      issue_json = {
        id: issue.id,
        subject: issue.subject,
        project: {
          id: issue.project.id,
          name: issue.project.name,
        },
        tracker: {
          id: issue.tracker.id,
          name: issue.tracker.name,
        },
        status: {
          id: issue.status.id,
          name: issue.status.name,
        },
        priority: {
          id: issue.priority.id,
          name: issue.priority.name,
        },
        author: {
          id: issue.author.id,
          name: issue.author.name,
        },
        description: issue.description,
        start_date: issue.start_date,
        due_date: issue.due_date,
        done_ratio: issue.done_ratio,
        is_private: issue.is_private,
        estimated_hours: issue.estimated_hours,
        total_estimated_hours: issue.total_estimated_hours,
        spent_hours: issue.spent_hours,
        total_spent_hours: issue.total_spent_hours,
        created_on: issue.created_on,
        updated_on: issue.updated_on,
        closed_on: issue.closed_on,
        journals: issue.journals.map do |journal|
          {
            id: journal.id,
            user: {
              id: journal.user.id,
              name: journal.user.name,
            },
            notes: journal.notes,
            created_on: journal.created_on,
            updated_on: journal.updated_on,
            private_notes: journal.private_notes,
            details: journal.details.map do |detail|
              {
                id: detail.id,
                property: detail.property,
                prop_key: detail.prop_key,
                value: detail.value,
                old_value: detail.old_value,
              }
            end,
          }
        end,

      }
      issue_json
    end

    def read_project(args = {})
      project_id = args["id"]
      project = Project.find(project_id)
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
        subprojects: project.children.map do |child|
          {
            id: child.id,
            name: child.name,
            identifier: child.identifier,
            description: child.description,
          }
        end,
      }
      project_json
    end
  end
end
