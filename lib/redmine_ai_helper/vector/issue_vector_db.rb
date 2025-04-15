require "json"

module RedmineAiHelper
  module Vector
    class IssueVectorDb < VectorDb
      def index_name
        "RedmineIssue"
      end

      def data_to_jsontext(issue)
        json = {
          id: issue.id,
          project_name: issue.project.name,
          author_name: issue.author&.name,
          subject: issue.subject,
          description: issue.description,
          status: issue.status.name,
          priority: issue.priority.name,
          assigned_to_name: issue.assigned_to&.name,
          created_on: issue.created_on,
          updated_on: issue.updated_on,
          tracker_name: issue.tracker.name,
          comments: issue.journals.map do |journal|
            {
              user_name: journal.user&.name,
              notes: journal.notes,
              created_on: journal.created_on,
            }
          end,
        }
        JSON.pretty_generate(json)
      end
    end
  end
end
