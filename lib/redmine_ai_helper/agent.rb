require "redmine_ai_helper/llm"

module RedmineAiHelper
  class Agent
    def initialize(client)
      @client = client
    end

    def self.listTools()
      list = {
        tools: [
          {
            name: "read_issue",
            description: "Read an issue from the database and return it as a JSON object.",
            arguments: {
              schema: {
                type: "object",
                properties: {
                  id: "integer",
                },
                required: ["id"],
              },
            },
          },
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
            name: "capable_issue_properties",
            description: "Return properties that can be assigned to an issue for the specified project, such as status, tracker, custom fields, etc. It can be used to obtain the ID of the items to be searched when searching for tickets using generate_issue_search_url.",
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
                          enum: ["tracker_id", "status_id", "priority_id", "category_id", "version_id", "created_on", "updated_on", "subject", "description", "assigned_to_id", "author_id", "start_date", "due_date", "done_ratio", "estimated_hours", "total_estimated_hours", "spent_hours", "total_spent_hours"],
                        },
                        operator: {
                          type: "string",
                          enum: ["==", "!=", ">", "<", ">=", "<=", "*", "!*", "o", "!o", "c", "!c"],
                          description: "Operators: == (equal), != (not equal), > (greater than), < (less than), >= (greater than or equal), <= (less than or equal), * (contains), !* (does not contain), o (open), !o (closed), c (is), !c (is not)",
                        },
                        value: {
                          "anyOf": [
                            { type: "string" },
                            { type: "array", items: { type: "string" } },
                          ],
                        },
                      },
                      required: ["field_name", "operator", "value"],
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
                          enum: ["==", "!=", ">", "<", ">=", "<=", "*", "!*", "o", "!o", "c", "!c"],
                          description: "Operators: == (equal), != (not equal), > (greater than), < (less than), >= (greater than or equal), <= (less than or equal), * (contains), !* (does not contain), o (open), !o (closed), c (is), !c (is not)",
                        },
                        value: "string",
                      },
                      required: ["field_id", "operator", "value"],
                    },
                  },
                },
                required: ["project_id", "fields", "custom_fields"],
                is_open: "boolean",
              },
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
      sym_args = args.deep_symbolize_keys
      issue_id = sym_args[:id]
      issue = Issue.find_by(id: issue_id)
      return { error: "Issue not found" } unless issue

      # Check if the issue is visible to the current user
      return { error: "You don't have permission to view this issue" } unless issue.visible?

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
        children: issue.children.map do |child|
          {
            id: child.id,
            tracker: {
              id: child.tracker.id,
              name: child.tracker.name,
            },
            subject: child.subject,
          }
        end,
        relations: issue.relations.map do |relation|
          {
            id: relation.id,
            issue_to_id: relation.issue_to_id,
            issue_from_id: relation.issue_from_id,
            relation_type: relation.relation_type,
            delay: relation.delay,
          }
        end,
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
        return { error: "No id or name or Identifier specified." }
      end

      return { error: "Project not found" } unless project
      return { error: "You don't have permission to view this project" } unless project.visible?
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
      project_json
    end

    # Return properties that can be assigned to an issue for the specified project, such as status, tracker, custom fields, etc.
    def capable_issue_properties(args = {})
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
        return { error: "No id or name or Identifier specified." }
      end
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

      properties
    end

    # フィルター条件からIssueを検索するためのURLを生成する
    #           {
    #   name: "generate_issue_search_url",
    #   description: "Generate a URL for searching issues based on the filter conditions. For search items with '_id', specify the ID instead of the name of the search target. If you do not know the ID, you need to call capable_issue_properties in advance to obtain the ID.",
    #   arguments: {
    #     schema: {
    #       type: "object",
    #       properties: {
    #         project_id: "integer",
    #         fields: {
    #           type: "array",
    #           items: {
    #             type: "object",
    #             properties: {
    #               field_name: {
    #                 type: "string",
    #                 enum: ["tracker_id", "status_id", "priority_id", "category_id", "version_id", "created_on", "updated_on", "subject", "description", "assigned_to_id", "author_id", "start_date", "due_date", "done_ratio", "estimated_hours", "total_estimated_hours", "spent_hours", "total_spent_hours"],
    #               },
    #               operator: {
    #                 type: "string",
    #                 enum: ["==", "!=", ">", "<", ">=", "<=", "*", "!*", "o", "!o", "c", "!c"],
    #                 description: "Operators: == (equal), != (not equal), > (greater than), < (less than), >= (greater than or equal), <= (less than or equal), * (contains), !* (does not contain), o (open), !o (closed), c (is), !c (is not)",
    #               },
    #               value: {
    #                 "anyOf": [
    #                   { type: "string" },
    #                   { type: "array", items: { type: "string" } },
    #                 ],
    #               },
    #             },
    #             required: ["field_name", "operator", "value"],
    #           },
    #         },
    #         custom_fields: {
    #           type: "array",
    #           items: {
    #             type: "object",
    #             properties: {
    #               field_id: "integer",
    #               operator: {
    #                 type: "string",
    #                 enum: ["==", "!=", ">", "<", ">=", "<=", "*", "!*", "o", "!o", "c", "!c"],
    #                 description: "Operators: == (equal), != (not equal), > (greater than), < (less than), >= (greater than or equal), <= (less than or equal), * (contains), !* (does not contain), o (open), !o (closed), c (is), !c (is not)",
    #               },
    #               value: "string",
    #             },
    #             required: ["field_id", "operator", "value"],
    #           },
    #         },
    #       },
    #       required: ["project_id", "fields", "custom_fields"],
    #       is_open: "boolean",
    #     },
    #   },
    # }
    def generate_issue_search_url(args = {})
      sym_args = args.deep_symbolize_keys
      project_id = sym_args[:project_id]
      project = Project.find(project_id)
      fields = sym_args[:fields]
      custom_fields = sym_args[:custom_fields]
      url = "/projects/#{project}/issues?"
      url += "utf8=%E2%9C%93&set_filter=1"

      field_params = {}
      fields.each do |field|
        field_name = field[:field_name]
        operator = field[:operator]
        value = field[:value]
        field_params[field_name] ||= { operator: operator, values: [] }
        field_params[field_name][:values] += Array(value)
      end

      field_params.each do |field_name, params|
        operator = params[:operator]
        values = params[:values]
        url += "&f[]=#{field_name}&op[#{field_name}]=#{operator}"
        values.each do |v|
          url += "&v[#{field_name}][]=#{v}"
        end
      end

      custom_fields.each do |field|
        field_id = field[:field_id]
        operator = field[:operator]
        value = field[:value]
        url += "&f[]=cf_#{field_id}&op[cf_#{field_id}]=#{operator}&v[cf_#{field_id}]=#{value}"
      end

      url += "&f[]=status_id&op[status_id]=o&v[status_id][]=open" if sym_args[:is_open]

      return { url: url }
    end
  end
end
