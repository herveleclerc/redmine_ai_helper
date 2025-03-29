require "redmine_ai_helper/base_tool_provider"
require_relative "./issue_update_tool_provider"

module RedmineAiHelper
  module ToolProviders
    class IssueToolProvider < RedmineAiHelper::BaseToolProvider

      define_function :read_issues, description: "Read an issue from the database and return it as a JSON object. It returns the issue ID, subject, project, tracker, status, priority, author, assigned_to, description, start_date, due_date, done_ratio, is_private, estimated_hours, total_estimated_hours, spent_hours, total_spent_hours, created_on, updated_on, closed_on, issue_url, attachments, children and relations." do
        property :issue_ids, type: "array", description: "The issue ID array to read.", required: true do
          item type: "integer", description: "The issue ID to read."
        end
      end
      # Read an issue from the database and return it as a JSON object.
      def read_issues(issue_ids:)
        raise("Issue ID array is required.") if issue_ids.empty?
        issues = []
        Issue.where(id: issue_ids).each do |issue|

          # Check if the issue is visible to the current user
          next unless issue.visible?

          issues << generate_issue_data(issue)
        end

        raise("Issue not found") if issues.empty?

        tool_response(content: {issues: issues})
      end

      define_function :capable_issue_properties, description: "Return properties that can be assigned to an issue for the specified project, such as status, tracker, custom fields, etc. You must specify one of project_id, project_name, or project_identifier." do
        property :project_id, type: "integer", description: "The project ID of the project to return.", required: false
        property :project_name, type: "string", description: "The project name of the project to return.", required: false
        property :project_identifier, type: "string", description: "The project identifier of the project to return.", required: false
      end
      # Return properties that can be assigned to an issue for the specified project, such as status, tracker, custom fields, etc.
      def capable_issue_properties(project_id: nil, project_name: nil, project_identifier: nil)
        project = nil
        if project_id
          project = Project.find_by(id: project_id)
        elsif project_name
          project = Project.find_by(name: project_name)
        elsif project_identifier
          project = Project.find_by(identifier: project_identifier)
        else
          raise("No id or name or Identifier specified.")
        end

        raise("Project not found.") unless project

        properties = {
          trackers: project.trackers.map do |tracker|
            {
              id: tracker.id,
              name: tracker.name,
            }
          end,
          statuses: IssueStatus.all.map do |status|
            {
              id: status.id,
              name: status.name,
            }
          end,
          priorities: IssuePriority.all.map do |priority|
            {
              id: priority.id,
              name: priority.name,
            }
          end,
          categories: project.issue_categories.map do |category|
            {
              id: category.id,
              name: category.name,
            }
          end,
          versions: project.versions.map do |version|
            {
              id: version.id,
              name: version.name,
            }
          end,
          issue_custom_fields: project.issue_custom_fields.map do |field|
            {
              id: field.id,
              name: field.name,
              type: field.field_format,
              possible_values: field.possible_values,
              is_required: field.is_required,
            }
          end,
        }

        tool_response(content: properties)
      end

      define_function :validate_new_issue, description: "Validate the parameters for creating a new issue. It can be used to check if the parameters are correct before creating a new issue." do
        property :project_id, type: "integer", description: "The project ID of the project to create the issue in.", required: true
        property :tracker_id, type: "integer", description: "The tracker ID of the issue to create.", required: true
        property :subject, type: "string", description: "The subject of the issue to create.", required: true
        property :status_id, type: "integer", description: "The status ID of the issue to create.", required: true
        property :priority_id, type: "integer", description: "The priority ID of the issue to create.", required: false
        property :category_id, type: "integer", description: "The category ID of the issue to create.", required: false
        property :version_id, type: "integer", description: "The version ID of the issue to create.", required: false
        property :assigned_to_id, type: "integer", description: "The assigned_to ID of the issue to create.", required: false
        property :description, type: "string", description: "The description of the issue to create.", required: false
        property :start_date, type: "string", description: "The start date of the issue to create.", required: false
        property :due_date, type: "string", description: "The due date of the issue to create.", required: false
        property :done_ratio, type: "integer", description: "The done ratio of the issue to create.", required: false
        property :is_private, type: "boolean", description: "Whether the issue is private or not. Default is false."
        property :estimated_hours, type: "string", description: "The estimated hours of the issue to create.", required: false
        property :custom_fields, type: "array", description:"Custom fields for the new issue." do
          item type: "object", description: "The custom field of the issue to create." do
            property :field_id, type: "integer", description: "The field ID of the custom field.", required: true
            property :value, type: "string", description: "The value of the custom field.", required: true
          end
        end
      end
      # Validate the parameters for creating a new issue
      def validate_new_issue(project_id:, tracker_id:, subject:, status_id:, priority_id: nil, category_id: nil, version_id: nil, assigned_to_id: nil, description: nil, start_date: nil, due_date: nil, done_ratio: nil, is_private: false, estimated_hours: nil, custom_fields: [])
        issue_update_provider = IssueUpdateToolProvider.new
        return issue_update_provider.create_new_issue(project_id: project_id, tracker_id: tracker_id, subject: subject, status_id: status_id, priority_id: priority_id, category_id: category_id, version_id: version_id, assigned_to_id: assigned_to_id, description: description, start_date: start_date, due_date: due_date, done_ratio: done_ratio, is_private: is_private, estimated_hours: estimated_hours, custom_fields: custom_fields, validate_only: true)
      end

      define_function :validate_update_issue, description: "Validate the parameters for updating an issue. It can be used to check if the parameters are correct before updating an issue." do
        property :issue_id, type: "integer", description: "The issue ID of the issue to update.", required: true
        property :subject, type: "string", description: "The subject of the issue to update.", required: false
        property :tracker_id, type: "integer", description: "The tracker ID of the issue to update.", required: false
        property :status_id, type: "integer", description: "The status ID of the issue to update.", required: false
        property :priority_id, type: "integer", description: "The priority ID of the issue to update.", required: false
        property :category_id, type: "integer", description: "The category ID of the issue to update.", required: false
        property :version_id, type: "integer", description: "The version ID of the issue to update.", required: false
        property :assigned_to_id, type: "integer", description: "The assigned_to ID of the issue to update.", required: false
        property :description, type: "string", description: "The description of the issue to update.", required: false
        property :start_date, type: "string", description: "The start date of the issue to update.", required: false
        property :due_date, type: "string", description: "The due date of the issue to update.", required: false
        property :done_ratio, type: "integer", description: "The done ratio of the issue to update.", required: false
        property :is_private, type: "boolean", description: "Whether the issue is private or not. Default is false."
        property :estimated_hours, type: "string", description: "The estimated hours of the issue to update.", required: false
        property :custom_fields, type: "array", description: "The custom fields of the issue to update.", required: false do
          item type: "object", description: "The custom field of the issue to update." do
            property :field_id, type: "integer", description: "The field ID of the custom field.", required: true
            property :value, type: "string", description: "The value of the custom field.", required: true
          end
        end
        property :comment_to_add, type: "string", description: "Comment to add to the issue. To insert a newline, you need to insert a blank line. Otherwise, it will be concatenated into a single line.", required: false
      end
      # Validate the parameters for updating an issue
      def validate_update_issue(issue_id:, subject: nil, tracker_id: nil, status_id: nil, priority_id: nil, category_id: nil, version_id: nil, assigned_to_id: nil, description: nil, start_date: nil, due_date: nil, done_ratio: nil, is_private: false, estimated_hours: nil, custom_fields: [], comment_to_add: nil)
        issue_update_provider = IssueUpdateToolProvider.new
        return issue_update_provider.update_issue(issue_id: issue_id, subject: subject, tracker_id: tracker_id, status_id: status_id, priority_id: priority_id, category_id: category_id, version_id: version_id, assigned_to_id: assigned_to_id, description: description, start_date: start_date, due_date: due_date, done_ratio: done_ratio, is_private: is_private, estimated_hours: estimated_hours, custom_fields: custom_fields, comment_to_add: comment_to_add, validate_only: true)
      end

      define_function :generate_issue_search_url, description: "Generate a URL for searching issues based on the filter conditions. For search items with '_id', specify the ID instead of the name of the search target. If you do not know the ID, you need to call capable_issue_properties in advance to obtain the ID." do
        property :project_id, type: "integer", description: "The project ID of the project to search in.", required: true
        property :fields, type: "array", description:"Search fields for the issue." do
          item type: "object", description: "Search field for the issue." do
            property :field_name, type: "string", description: "The name of the field to search.", required: true
            property :operator, type: "string", description: "The operator to use for the search.", required: true
            property :values, type: "array", description:"The values to search for.", required: true do
              item type: "string", description: "The value to search for."
            end
          end
        end
        property :date_fields, type: "array", description:"Search fields for the issue." do
          item type: "object", description: "Search field for the issue." do
            property :field_name, type: "string", description: "The name of the field to search.", required: true
            property :operator, type: "string", description: "The operator to use for the search.", required: true
            property :values, type: "array", description:"The values to search for.", required: true do
              item type: "string", description: "The value to search for."
            end
          end
        end
        property :time_fields, type: "array", description:"Search fields for the issue." do
          item type: "object", description: "Search field for the issue." do
            property :field_name, type: "string", description: "The name of the field to search.", required: true
            property :operator, type: "string", description: "The operator to use for the search.", required: true
            property :values, type: "array", description:"The values to search for.", required: true do
              item type: "string", description: "The value to search for."
            end
          end
        end
        property :number_fields, type: "array", description:"Search fields for the issue." do
          item type: "object", description: "Search field for the issue." do
            property :field_name, type: "string", description: "The name of the field to search.", required: true
            property :operator, type: "string", description: "The operator to use for the search.", required: true
            property :values, type: "array", description:"The values to search for.", required: true do
              item type: "integer", description: "The value to search for."
            end
          end
        end
        property :text_fields, type: "array", description:"Search fields for the issue." do
          item type: "object", description: "Search field for the issue." do
            property :field_name, type: "string", description: "The name of the field to search.", required: true
            property :operator, type: "string", description: "The operator to use for the search.", required: true
            property :value, type: "array", description:"The values to search for.", required: true do
              item type: "string", description: "The value to search for."
            end
          end
        end
        property :status_field, type: "array", description:"Search fields for the issue." do
          item type: "object", description: "Search field for the issue." do
            property :field_name, type: "string", description: "The name of the field to search.", required: true
            property :operator, type: "string", description: "The operator to use for the search.", required: true
            property :values, type: "array", description:"The values to search for.", required: true do
              item type: "integer", description: "The value to search for."
            end
          end
        end
        property :custom_fields, type: "array", description:"Search fields for the issue." do
          item type: "object", description: "Search field for the issue." do
            property :field_id, type: "integer", description: "The ID of the custom field to search.", required: true
            property :operator, type: "string", description: "The operator to use for the search.", required: true
            property :values, type: "array", description:"The values to search for.", required: true do
              item type: "string", description: "The value to search for."
            end
          end
        end
      end

      # Generate a URL with query strings to search for issues based on filter conditions
      def generate_issue_search_url(project_id:, fields: [], date_fields: [], time_fields: [], number_fields: [], text_fields: [], status_field: [], custom_fields: [])
        project = Project.find(project_id)

        if fields.empty? && date_fields.empty? && time_fields.empty? && number_fields.empty? && text_fields.empty? && status_field.empty? && custom_fields.empty?
          return tool_response(content: { url: "/projects/#{project.identifier}/issues" })
        end

        validate_errors = generate_issue_search_url_validate(fields, date_fields, time_fields, number_fields, text_fields, status_field, custom_fields)
        raise(validate_errors.join("\n")) if validate_errors.length > 0

        params = { fields: [], operators: {}, values: {} }
        params[:fields] << "project_id"
        params[:operators]["project_id"] = "="
        params[:values]["project_id"] = [project_id.to_s]
        fields.each do |field|
          params[:fields] << field[:field_name]
          params[:operators][field[:field_name]] = field[:operator]
          params[:values][field[:field_name]] = field[:values]
        end

        date_fields.each do |field|
          params[:fields] << field[:field_name]
          params[:operators][field[:field_name]] = field[:operator]
          params[:values][field[:field_name]] = field[:values]
        end

        time_fields.each do |field|
          params[:fields] << field[:field_name]
          params[:operators][field[:field_name]] = field[:operator]
          params[:values][field[:field_name]] = field[:values]
        end

        number_fields.each do |field|
          params[:fields] << field[:field_name]
          params[:operators][field[:field_name]] = field[:operator]
          params[:values][field[:field_name]] = field[:values].map(&:to_s)
        end

        text_fields.each do |field|
          params[:fields] << field[:field_name]
          params[:operators][field[:field_name]] = field[:operator]
          params[:values][field[:field_name]] = field[:value]
        end

        status_field.each do |field|
          params[:fields] << field[:field_name]
          params[:operators][field[:field_name]] = field[:operator]
          params[:values][field[:field_name]] = field[:values].map(&:to_s)
        end

        builder = IssueQueryBuilder.new(params)
        custom_fields.each do |field|
          builder.add_custom_field_filter(field[:field_id], field[:operator], field[:values].map(&:to_s))
        end

        url = builder.generate_query_string(project)

        tool_response(content: {url: url})
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
            name: issue.assigned_to.name,
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
          issue_url: issue.id ? issue_url(issue, only_path: true) : nil,
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

      # Validate the parameters for generate_issue_search_url
      def generate_issue_search_url_validate(fields, date_fields, time_fields, number_fields, text_fields, status_field, custom_fields)
        errors = []

        fields.each do |field|
          if field[:field_name].match(/_id$/) && field[:values].length > 0
            field[:values].each do |value|
              unless value.to_s.match(/^\d+$/)
                errors << "The #{field[:field_name]} requires a numeric value. But the value is #{value}."
              end
            end
          end
        end

        date_fields.each do |field|
          case field[:operator]
          when "=", ">=", "<=", "><"
            if field[:values].length == 0
              errors << "The #{field[:field_name]} and #{field[:operator]} requires an absolute date value. But no value is specified."
            end
            field[:values].each do |value|
              unless value.match(/\d{4}-\d{2}-\d{2}/)
                errors << "The #{field[:field_name]} and #{field[:operator]} requires an absolute date value in the format YYYY-MM-DD. But the value is #{value}."
              end
            end
          when "<t+", ">t+", "t+", ">t-", "<t-", "t-"
            if field[:values].length == 0
              errors << "The #{field[:field_name]} and #{field[:operator]} requires a relative date value. But no value is specified."
            end
            field[:values].each do |value|
              unless value.match(/\d+/)
                errors << "The #{field[:field_name]} and #{field[:operator]} requires a relative date value. But the value is #{value}."
              end
            end
          else
            unless field[:values].length == 0
              errors << "The #{field[:name]} and #{field[:operator]} does not require a value. But the value is specified."
            end
          end
        end

        errors
      end

      # Redmineのチケット検索用URLを作成するクラス
      # # 使用例
      # params = {
      #   fields: ["tracker_id", "created_on"],
      #   operators: { "tracker_id" => "=", "created_on" => "><" },
      #   values: { "tracker_id" => ["2"], "created_on" => ["2025-01-01", "2025-01-31"] },
      # }
      # defaults = {}
      # builder = IssueQueryBuilder.new(params, defaults)
      # カスタムフィールドのフィルターを追加
      # ここでは値を配列として渡します
      # builder.add_custom_field_filter(1, "=", ["example_value1", "example_value2"])
      # project = Project.find(1)
      # puts builder.generate_query_string(project)
      #
      class IssueQueryBuilder
        include Rails.application.routes.url_helpers

        def initialize(params, defaults = {})
          @query = IssueQuery.new
          # @query.add_filter("set_filter", "=", "1")
          inspect = "Initializing query with params: #{params.inspect}"
          params[:fields].each do |field|
            operator = params[:operators][field]
            values = params[:values][field]
            @query.add_filter(field, operator, values)
          end
          @query.column_names = ["project", "tracker", "status", "subject", "priority", "assigned_to", "updated_on"]
          @query.sort_criteria = [["priority", "desc"], ["updated_on", "desc"]]
        end

        def add_custom_field_filter(custom_field_id, operator, values)
          field = "cf_#{custom_field_id}"
          @query.add_filter(field, operator, values)
        end

        def generate_query_string(project)
          query_params = @query.as_params
          query_params.delete(:set_filter)
          query_string = query_params.to_query
          # "/projects/#{project.identifier}/issues?set_filter=1&#{query_string}"
          "#{project_issues_path(project)}?set_filter=1&#{query_string}"
        end
      end
    end
  end
end
