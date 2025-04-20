require "json"

module RedmineAiHelper
  module Vector
    class IssueVectorDb < VectorDb
      def index_name
        "RedmineIssue"
      end

      def ask_with_filter(query:, filter: nil, k: 20)
        return [] unless client
        client.ask_with_filter(
          query: query,
          k: k,
          filter: filter,
        )
      end

      def data_exists?(object_id)
        Issue.exists?(id: object_id)
      end

      def data_to_json(issue)
        payload = {
          issue_id: issue.id,
          project_id: issue.project.id,
          project_name: issue.project.name,
          author_id: issue.author&.id,
          author_name: issue.author&.name,
          subject: issue.subject,
          description: issue.description,
          status_id: issue.status.id,
          status: issue.status.name,
          priority_id: issue.priority.id,
          priority: issue.priority.name,
          assigned_to_id: issue.assigned_to&.id,
          assigned_to_name: issue.assigned_to&.name,
          created_on: issue.created_on,
          updated_on: issue.updated_on,
          due_date: issue.due_date,
          tracker_id: issue.tracker.id,
          tracker_name: issue.tracker.name,
          version_id: issue.fixed_version&.id,
          version_name: issue.fixed_version&.name,
          category_name: issue.category&.name,
        }
        content = issue.subject + " " + issue.description
        content += " " + issue.journals.map { |journal| journal.notes }.join(" ")

        return { content: content, payload: payload }
      end
    end
  end
end
