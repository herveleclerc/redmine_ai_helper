require "redmine_ai_helper/base_tool_provider"

module RedmineAiHelper
  module ToolProviders
    class IssueToolProvider < RedmineAiHelper::BaseToolProvider
      def self.list_tools()
        list = {
          tools: [
            {
              name: "read_issues",
              description: "Read issues from the database and return it, including journals, attachments, relations, and revisions. Attachments including the URL to download the file which starts a root path of this site.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    id: {
                      type: "array",
                      items: { type: "integer" },
                    },
                  },
                  required: ["id"],
                  description: "Issue ID array. At least one ID is required.",
                },
              },
            },
            {
              name: "create_new_issue",
              description: "Create a new issue in the database. It can also be used to validate the issue without creating it.",
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
                    validate_only: {
                      type: "boolean",
                      default: false,
                      description: "If true, the issue will not be created, but the validation result will be returned.",
                    },
                  },
                  required: ["project_id", "tracker_id", "subject", "status_id"],
                  description: "Project ID, Tracker ID, Status ID and Subject are required. Other fields are optional.",
                },
              },
            },
            {
              name: "update_issue",
              description: "Update an issue in the database. It can also be used to add a comment to the issue. It can also be used to validate the issue without updating it.",
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
                    validate_only: {
                      type: "boolean",
                      default: false,
                      description: "If true, the issue will not be updated, but the validation result will be returned.",
                    },
                  },
                  required: ["issue_id"],
                  description: "Issue ID is required. Other fields are optional. If you do not specify a field, it will not be updated.",
                },
              },
            },
            {
              name: "capable_issue_properties",
              description: "Return properties that can be assigned to an issue for the specified project, It includes trackers, statuses, priorities, categories, versions and custom fields. It can be used to obtain the ID of the items to be searched when searching for tickets using generate_issue_search_url.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    project_id: "integer",
                    project_name: "string",
                    project_identifier: "string",
                  },
                  "anyOf": [
                    { required: ["project_id"] },
                    { required: ["project_name"] },
                    { required: ["project_identifier"] },
                  ],
                },
              },
            },
            {
              name: "generate_issue_search_url",
              description: "Generate a URL for searching issues based on the filter conditions. For search items with '_id', specify the ID instead of the name of the search target. If you do not know the ID, you need to call capable_issue_properties in advance to obtain the ID.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    project_id: "integer",
                    fields: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          field_name: {
                            type: "string",
                            enum: ["tracker_id", "priority_id", "category_id", "version_id", "assigned_to_id", "author_id", "start_date"],
                          },
                          operator: {
                            type: "string",
                            enum: ["=", "!", "*", "!*", "!p", "cf", "h"],
                            description: "Operators: = (equal), != (not equal), * (all), !* (none), !p (has never been), cf (changed from), h (has been)",
                          },
                          values: {
                            type: "array",
                            items: { type: "string" },
                          },
                        },
                        required: ["field_name", "operator", "values"],
                      },
                    },
                    date_fields: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          field_name: {
                            type: "string",
                            enum: ["created_on", "updated_on", "start_date", "due_date"],
                          },
                          operator: {
                            type: "string",
                            enum: ["=", ">=", "<=", "><", "<t+", ">t+", "t+", "t", "ld", "w", "lw", "l2w", "m", "lm", "y", ">t-", "<t-", "t-", "!*", "*"],
                            description: "Operators: = (equal), >= (greater than or equal), <= (less than or equal), >< (between), <t+ (Within the next n days from today), >t+ (More than n days from today), t+ (n days from today), t (today), ld (last day), w (this week), lw (last week), l2w (last 2 weeks), m (this month), lm (last month), y (this year), >t- (More than n days ago), <t- (Within the past n days), t (today), t- (n days ago), !* (none), * (any)",
                          },
                          values: {
                            type: "array",
                            items: { type: "string" },
                            description: "Specify absolute dates in YYYY-MM-DD format. For relative dates, specify only the number. Depending on the operator, multiple values may be specified, or no value may be required.
                          The following operations must specify absolute dates: =, >=, <=, ><
                          The following operations must specify relative dates: <t+, >t+, t+, >t-, <t-, t-
                          No value is needed for other operations
                          ",
                          },
                        },
                        required: ["field_name", "operator", "values"],
                      },
                    },
                    time_fields: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          field_name: {
                            type: "string",
                            enum: ["estimated_hours", "spent_hours"],
                          },
                          operator: {
                            type: "string",
                            enum: ["=", ">=", "<=", "><", "!*", "*"],
                            description: "Operators: = (equal), >= (greater than or equal), <= (less than or equal), >< (between), !* (none), * (any)",
                          },
                          values: {
                            type: "array",
                            items: { type: "string" },
                          },
                        },
                        required: ["field_name", "operator", "values"],
                      },
                    },
                    number_fields: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          field_name: {
                            type: "string",
                            enum: ["done_ratio"],
                          },
                          operator: {
                            type: "string",
                            enum: ["=", ">=", "<=", "><", "!*", "*"],
                            description: "Operators: = (equal), >= (greater than or equal), <= (less than or equal), >< (between), !* (none), * (any)",
                          },
                          values: {
                            type: "array",
                            items: { type: "integer" },
                          },
                        },
                        required: ["field_name", "operator", "values"],
                      },
                    },
                    text_fields: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          field_name: {
                            type: "string",
                            enum: ["subject", "description", "notes"],
                          },
                          operator: {
                            type: "string",
                            enum: ["~", "!~", "=", "!", "*", "!*"],
                            description: "Operators: ~ (contains), !~ (does not contain), = (equal), != (not equal), * (any value set), !* (no value set)",
                          },
                          value: {
                            type: "array",
                            items: { type: "string" },
                          },
                        },
                        required: ["field_name", "operator", "value"],
                      },
                    },
                    status_field: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          field_name: {
                            type: "string",
                            enum: ["status_id"],
                          },
                          operator: {
                            type: "string",
                            enum: ["=", "!", "o", "c", "*"],
                            description: "Operators: = (exact match), ! (not equal), o (open), c (closed), * (any value set)",
                          },
                          values: {
                            type: "array",
                            items: { type: "integer" },
                          },
                        },
                        required: ["field_name", "operator", "values"],
                      },
                    },
                    custom_fields: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          field_id: "integer",
                          operator: {
                            type: "string",
                            enum: ["=", "!", "!*", "*", "~", "!~", "^", "$", ">=", "<=", "><", "<t", ">", "t+", "t", "w", ">t-", "<t-"],
                            description: "Operators: = (equal), != (not equal), !* (no value set), * (any value set), ~ (contains), !~ (does not contain), ^ (starts with), $ (ends with), >= (greater than or equal), <= (less than or equal), >< (between), <t+ (within the next n days), >t+ (more than n days ahead), t+ (n days in the future), t (today), w (this week), >t- (more than n days ago), <t- (within the past n days)",
                          },
                          values: {
                            type: "array",
                            items: { type: "integer" },
                          },
                        },
                        required: ["field_id", "operator", "values"],
                      },
                    },
                  },
                  required: ["project_id"],
                },
              },
            },
          ],
        }
        list
      end

      # Read an issue from the database and return it as a JSON object.
      # args: { id: issue_id }
      def read_issues(args = {})
        sym_args = args.deep_symbolize_keys
        issue_ids = sym_args[:id]
        return ToolResponse.create_error("Issue ID array is required.") if issue_ids.empty?
        issues = []
        Issue.where(id: issue_ids).each do |issue|

          # Check if the issue is visible to the current user
          next unless issue.visible?

          issues << generate_issue_data(issue)
        end

        issues_json = { issues: issues }
        ToolResponse.create_success(issues_json)
      end

      # Create a new issue in the database.
      def create_new_issue(args = {})
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

        validate_only = sym_args[:validate_only] || false
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

      # Return properties that can be assigned to an issue for the specified project, such as status, tracker, custom fields, etc.
      def capable_issue_properties(args = {})
        sym_args = args.deep_symbolize_keys
        project_id = sym_args[:project_id]
        project_name = sym_args[:project_name]
        project_identifier = sym_args[:project_identifier]
        project = nil
        if project_id
          project = Project.find_by(id: project_id)
        elsif project_name
          project = Project.find_by(name: project_name)
        elsif project_identifier
          project = Project.find_by(identifier: project_identifier)
        else
          return ToolResponse.create_error("No id or name or Identifier specified.")
        end

        return ToolResponse.create_error("Project not found.") unless project

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

        ToolResponse.create_success properties
      end

      # Update an issue in the database.
      # args: { issue_id: issue_id, subject: "string", tracker_id: tracker_id, status_id: status_id, priority_id: priority_id, category_id: category_id, version_id: version_id, assigned_to_id: assigned_to_id, description: "string", start_date: "string", due_date: "string", done_ratio: done_ratio, is_private: is_private, estimated_hours: estimated_hours, custom_fields: [{ field_id: field_id, value: "string" }], comment_to_add: "string" }
      def update_issue(args = {})
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

        validate_only = sym_args[:validate_only] || false
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

      # フィルター条件からIssueを検索するためのURLをクエリーストリングを含めて生成する
      def generate_issue_search_url(args = {})
        sym_args = args.deep_symbolize_keys
        project_id = sym_args[:project_id]
        project = Project.find(project_id)
        fields = sym_args[:fields] || []
        date_fields = sym_args[:date_fields] || []
        time_fields = sym_args[:time_fields] || []
        number_fields = sym_args[:number_fields] || []
        text_fields = sym_args[:text_fields] || []
        status_field = sym_args[:status_field] || []
        custom_fields = sym_args[:custom_fields] || []

        if fields.empty? && date_fields.empty? && time_fields.empty? && number_fields.empty? && text_fields.empty? && status_field.empty? && custom_fields.empty?
          return ToolResponse.create_success({ url: "/projects/#{project.identifier}/issues" })
        end

        validate_errors = generate_issue_search_url_validate(fields, date_fields, time_fields, number_fields, text_fields, status_field, custom_fields)
        return ToolResponse.create_error(validate_errors.join("\n")) if validate_errors.length > 0

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

        json = { url: url }
        ToolResponse.create_success json
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
