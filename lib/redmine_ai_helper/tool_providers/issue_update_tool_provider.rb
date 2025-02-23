require "redmine_ai_helper/base_tool_provider"

module RedmineAiHelper
  module ToolProviders
    class IssueUpdateToolProvider < RedmineAiHelper::BaseToolProvider
      def self.list_tools()
        list = {
          tools: [

            {
              name: "create_new_issue",
              description: "Create a new issue in the database. ",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    project_id: "integer",
                    tracker_id: "integer",
                    subject: "string",
                    status_id: "integer",
                    priority_id: "integer",
                    category_id: "integer",
                    version_id: "integer",
                    assigned_to_id: "integer",
                    description: "string",
                    start_date: "string",
                    due_date: "string",
                    done_ratio: "integer",
                    is_private: { type: "boolean", default: false },
                    estimated_hours: "float",
                    custom_fields: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          field_id: "integer",
                          value: "string",
                        },
                        required: ["field_id", "value"],
                      },
                    },
                  },
                  required: ["project_id", "tracker_id", "subject", "status_id"],
                  description: "Project ID, Tracker ID, Status ID and Subject are required. Other fields are optional.",
                },
              },
            },
            {
              name: "update_issue",
              description: "Update an issue in the database. It can also be used to add a comment to the issue.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    issue_id: "integer",
                    subject: "string",
                    tracker_id: "integer",
                    status_id: "integer",
                    priority_id: "integer",
                    category_id: "integer",
                    version_id: "integer",
                    assigned_to_id: "integer",
                    description: "string",
                    start_date: "string",
                    due_date: "string",
                    done_ratio: "integer",
                    is_private: "boolean",
                    estimated_hours: "float",
                    custom_fields: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          field_id: "integer",
                          value: "string",
                        },
                        required: ["field_id", "value"],
                      },
                    },
                    comment_to_add: {
                      type: "string",
                      description: "Comment to add to the issue. To insert a newline, you need to insert a blank line. Otherwise, it will be concatenated into a single line.",
                    },
                  },
                  required: ["issue_id"],
                  description: "Issue ID is required. Other fields are optional. If you do not specify a field, it will not be updated.",
                },
              },
            },
          ],
        }
        list
      end

      # Create a new issue in the database.
      def create_new_issue(args = {}, validate_only = false)
        sym_args = args.deep_symbolize_keys
        project_id = sym_args[:project_id]
        project = Project.find_by(id: project_id)
        return ToolResponse.create_error("Project not found. id = #{project_id}") unless project

        issue = Issue.new
        issue.project_id = project_id
        issue.author_id = User.current.id
        issue.tracker_id = sym_args[:tracker_id]
        issue.subject = sym_args[:subject]
        issue.status_id = sym_args[:status_id]
        issue.priority_id = sym_args[:priority_id]
        issue.category_id = sym_args[:category_id]
        issue.fixed_version_id = sym_args[:version_id]
        issue.assigned_to_id = sym_args[:assigned_to_id]
        issue.description = sym_args[:description]
        issue.start_date = sym_args[:start_date]
        issue.due_date = sym_args[:due_date]
        issue.done_ratio = sym_args[:done_ratio]
        issue.is_private = sym_args[:is_private] || false
        issue.estimated_hours = sym_args[:estimated_hours]

        custom_fields = sym_args[:custom_fields] || []
        custom_fields.each do |field|
          custom_field = CustomField.find(field[:field_id])
          next unless custom_field
          issue.custom_field_values = { custom_field.id => field[:value] }
        end

        if validate_only
          unless issue.valid?
            return ToolResponse.create_error("Validation failed. #{issue.errors.full_messages.join(", ")}")
          end
          return ToolResponse.create_success(generate_issue_data(issue))
        end
        unless issue.save
          return ToolResponse.create_error("Failed to create a new issue. #{issue.errors.full_messages.join(", ")}")
        end
        ToolResponse.create_success(generate_issue_data(issue))
      end

      # Update an issue in the database.
      # args: { issue_id: issue_id, subject: "string", tracker_id: tracker_id, status_id: status_id, priority_id: priority_id, category_id: category_id, version_id: version_id, assigned_to_id: assigned_to_id, description: "string", start_date: "string", due_date: "string", done_ratio: done_ratio, is_private: is_private, estimated_hours: estimated_hours, custom_fields: [{ field_id: field_id, value: "string" }], comment_to_add: "string" }
      def update_issue(args = {}, validate_only = false)
        sym_args = args.deep_symbolize_keys
        issue_id = sym_args[:issue_id]
        issue = Issue.find_by(id: issue_id)
        return ToolResponse.create_error("Issue not found. id = #{issue_id}") unless issue

        comment_to_add = sym_args[:comment_to_add]
        if comment_to_add
          issue.init_journal(User.current, comment_to_add)
        else
          issue.init_journal(User.current)
        end

        issue.subject = sym_args[:subject] if sym_args[:subject]
        issue.tracker_id = sym_args[:tracker_id] if sym_args[:tracker_id]
        issue.status_id = sym_args[:status_id] if sym_args[:status_id]
        issue.priority_id = sym_args[:priority_id] if sym_args[:priority_id]
        issue.category_id = sym_args[:category_id] if sym_args[:category_id]
        issue.fixed_version_id = sym_args[:version_id] if sym_args[:version_id]
        issue.assigned_to_id = sym_args[:assigned_to_id] if sym_args[:assigned_to_id]
        issue.description = sym_args[:description] if sym_args[:description]
        issue.start_date = sym_args[:start_date] if sym_args[:start_date]
        issue.due_date = sym_args[:due_date] if sym_args[:due_date]
        issue.done_ratio = sym_args[:done_ratio] if sym_args[:done_ratio]
        issue.is_private = sym_args[:is_private] if sym_args[:is_private]
        issue.estimated_hours = sym_args[:estimated_hours] if sym_args[:estimated_hours]

        custom_fields = sym_args[:custom_fields] || []
        custom_fields.each do |field|
          custom_field = CustomField.find(field[:field_id])
          next unless custom_field
          issue.custom_field_values = { custom_field.id => field[:value] }
        end

        if validate_only
          unless issue.valid?
            return ToolResponse.create_error("Validation failed. #{issue.errors.full_messages.join(", ")}")
          end
          return ToolResponse.create_success(generate_issue_data(issue))
        end

        unless issue.save
          return ToolResponse.create_error("Failed to update the issue #{issue.id}. #{issue.errors.full_messages.join(", ")}")
        end
        ToolResponse.create_success(generate_issue_data(issue))
      end

      private

      def generate_issue_data(issue)
        {
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
          assigned_to: issue.assigned_to ? {
            id: issue.assigned_to.id,
            name: issue.assigned_to.name
          } : nil,
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
          issue_url: issue.id ? issue_url(issue, only_path: true): nil,
          attachments: issue.attachments.map do |attachment|
            {
              id: attachment.id,
              filename: attachment.filename,
              filesize: attachment.filesize,
              content_type: attachment.content_type,
              created_on: attachment.created_on,
              attachment_url: attachment_path(attachment, only_path: false),
            }
          end,
          children: issue.children.filter { |child| child.visible? }.map do |child|
            {
              id: child.id,
              tracker: {
                id: child.tracker.id,
                name: child.tracker.name,
              },
              subject: child.subject,
              issue_url: issue_url(child, only_path: true),
            }
          end,
          relations: issue.relations.filter { |relation| relation.visible? }.map do |relation|
            {
              id: relation.id,
              issue_to_id: relation.issue_to_id,
              issue_from_id: relation.issue_from_id,
              relation_type: relation.relation_type,
              delay: relation.delay,
            }
          end,
          journals: issue.journals.filter { |journal| journal.visible? }.map do |journal|
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
          revisions: issue.changesets.map do |changeset|
            {
              repository_id: changeset.repository_id,
              revision: changeset.revision,
              committed_on: changeset.committed_on,
            }
          end,

        }
      end

    end
  end
end
