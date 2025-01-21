require "redmine_ai_helper/llm"

module RedmineAiHelper
  class Agent
    def initialize(client, model)
      @client = client
      @model = model
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
                          description: "Operators: = (equal), != (not equal), * (all), !* (none), !p (has nerver been), cf (changed from), h (has been)",
                        },
                        value: {
                          "anyOf": [
                            { type: "string" },
                            { type: "array", items: { type: "string" } },
                          ],
                        },
                      },
                      required: ["field_name", "operator"],
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
                        value: {
                          "anyOf": [
                            { type: "string" },
                            { type: "array", items: { type: "string" } },
                          ],
                        },
                      },
                      required: ["field_name", "operator"],
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
                        value: {
                          "anyOf": [
                            { type: "string" },
                            { type: "array", items: { type: "string" } },
                          ],
                        },
                      },
                      required: ["field_name", "operator"],
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
                        value: {
                          "anyOf": [
                            { type: "integer" },
                            { type: "array", items: { type: "integer" } },
                          ],
                        },
                      },
                      required: ["field_name", "operator"],
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
                          "anyOf": [
                            { type: "string" },
                            { type: "array", items: { type: "string" } },
                          ],
                        },
                      },
                      required: ["field_name", "operator"],
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
                        value: {
                          "anyOf": [
                            { type: "integer" },
                            { type: "array", items: { type: "integer" } },
                          ],
                        },
                      },
                      required: ["field_name", "operator"],
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
                        value: "string",
                      },
                      required: ["field_id", "operator"],
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
      project_id = sym_args[:project_id]
      project_name = sym_args[:project_name]
      project_identifier = sym_args[:project_identifier]
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

    # フィルター条件からIssueを検索するためのURLをクエリーストリングを含めて生成する
    # {
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
    #                 enum: ["tracker_id", "priority_id", "category_id", "version_id", "assigned_to_id", "author_id", "start_date"],
    #               },
    #               operator: {
    #                 type: "string",
    #                 enum: ["=", "!", "*", "!*", "!p", "cf", "h"],
    #                 description: "Operators: = (equal), != (not equal), * (all), !* (none), !p (has nerver been), cf (changed from), h (has been)",
    #               },
    #               value: {
    #                 "anyOf": [
    #                   { type: "string" },
    #                   { type: "array", items: { type: "string" } },
    #                 ],
    #               },
    #             },
    #             required: ["field_name", "operator"],
    #           },
    #         },
    #         date_fields: {
    #           type: "array",
    #           items: {
    #             type: "object",
    #             properties: {
    #               field_name: {
    #                 type: "string",
    #                 enum: ["created_on", "updated_on", "start_date", "due_date"],
    #               },
    #               operator: {
    #                 type: "string",
    #                 enum: ["=", ">=", "<=", "><", "<t+", ">t+", "t+", "t", "ld", "w", "lw", "l2w", "m", "lm", "y", ">t-", "<t-", "t-", "!*", "*"],
    #                 description: "Operators: = (equal), >= (greater than or equal), <= (less than or equal), >< (between), <t+ (Within the next n days from today), >t+ (More than n days from today), t+ (n days from today), t (today), ld (last day), w (this week), lw (last week), l2w (last 2 weeks), m (this month), lm (last month), y (this year), >t- (More than n days ago), <t- (Within the past n days), t (today), t- (n days ago), !* (none), * (any)",
    #               },
    #               value: {
    #                 "anyOf": [
    #                   { type: "string" },
    #                   { type: "array", items: { type: "string" } },
    #                 ],
    #               },
    #             },
    #             required: ["field_name", "operator"],
    #           },
    #         },
    #         time_fields: {
    #           type: "array",
    #           items: {
    #             type: "object",
    #             properties: {
    #               field_name: {
    #                 type: "string",
    #                 enum: ["estimated_hours", "spent_hours"],
    #               },
    #               operator: {
    #                 type: "string",
    #                 enum: ["=", ">=", "<=", "><", "!*", "*"],
    #                 description: "Operators: = (equal), >= (greater than or equal), <= (less than or equal), >< (between), !* (none), * (any)",
    #               },
    #               value: {
    #                 "anyOf": [
    #                   { type: "string" },
    #                   { type: "array", items: { type: "string" } },
    #                 ],
    #               },
    #             },
    #             required: ["field_name", "operator"],
    #           },
    #         },
    #         number_fields: {
    #           type: "array",
    #           items: {
    #             type: "object",
    #             properties: {
    #               field_name: {
    #                 type: "string",
    #                 enum: ["done_ratio"],
    #               },
    #               operator: {
    #                 type: "string",
    #                 enum: ["=", ">=", "<=", "><", "!*", "*"],
    #                 description: "Operators: = (equal), >= (greater than or equal), <= (less than or equal), >< (between), !* (none), * (any)",
    #               },
    #               value: {
    #                 "anyOf": [
    #                   { type: "integer" },
    #                   { type: "array", items: { type: "integer" } },
    #                 ],
    #               },
    #             },
    #             required: ["field_name", "operator"],
    #           },
    #         },
    #         text_field: {
    #           type: "array",
    #           items: {
    #             type: "object",
    #             properties: {
    #               field_name: {
    #                 type: "string",
    #                 enum: ["subject", "description", "notes"],
    #               },
    #               operator: {
    #                 type: "string",
    #                 enum: ["~", "!~", "=", "!", "*", "!*"],
    #                 description: "Operators: ~ (contains), !~ (does not contain), = (equal), != (not equal), * (any value set), !* (no value set)",
    #               },
    #               value: {
    #                 "anyOf": [
    #                   { type: "string" },
    #                   { type: "array", items: { type: "string" } },
    #                 ],
    #               },
    #             },
    #             required: ["field_name", "operator"],
    #           },
    #         },
    #         status_field: {
    #           type: "array",
    #           items: {
    #             type: "object",
    #             properties: {
    #               field_name: {
    #                 type: "string",
    #                 enum: ["status_id"],
    #               },
    #               operator: {
    #                 type: "string",
    #                 enum: ["=", "!", "o", "c", "*"],
    #                 description: "Operators: = (exact match), ! (not equal), o (open), c (closed), * (any value set)",
    #               },
    #               value: {
    #                 "anyOf": [
    #                   { type: "integer" },
    #                   { type: "array", items: { type: "integer" } },
    #                 ],
    #               },
    #             },
    #             required: ["field_name", "operator"],
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
    #                 enum: ["=", "!", "!*", "*", "~", "!~", "^", "$", ">=", "<=", "><", "<t", ">", "t+", "t", "w", ">t-", "<t-"],
    #                 description: "Operators: = (equal), != (not equal), !* (no value set), * (any value set), ~ (contains), !~ (does not contain), ^ (starts with), $ (ends with), >= (greater than or equal), <= (less than or equal), >< (between), <t+ (within the next n days), >t+ (more than n days ahead), t+ (n days in the future), t (today), w (this week), >t- (more than n days ago), <t- (within the past n days)",

    #               },
    #               value: "string",
    #             },
    #             required: ["field_id", "operator"],
    #           },
    #         },
    #       },
    #       required: ["project_id"],
    #     },
    #   },
    # },
    #
    # Redmine 6.0のチケット検索用クエリーストリングの仕様は以下の通りです:
    # ## 基本構造
    # 基本的なURLの構造は次のようになります:
    # ```
    # /issues?key1=value1&key2=value2&...
    # ```
    # ## 主要なパラメータ
    # 1. `set_filter=1`: フィルターを有効にする
    # 2. `f[]=`: フィルターフィールドを指定（複数指定可能）
    # 3. `op[field_name]=`: 演算子を指定
    # 4. `v[field_name][]=`: フィルター値を指定
    #
    # ## 演算子
    # フィールドタイプによって使用可能な演算子が異なります:
    #
    # - テキストフィールド: `~`（含む）, `!~`（含まない）, `=`, `!`
    # - 数値・日付フィールド: `=`, `>=`, `<=`, `><`（範囲）
    # - リストフィールド: `=`, `!`
    #
    # ## 特殊なフィルター
    #
    # - `*`: 任意の値
    # - `!*`: 値なし
    #
    # ## ページネーション
    #
    # - `offset`: スキップする結果の数
    # - `limit`: 返す結果の数（最大100）
    #
    # ## 例
    #
    # 1. オープンステータスのチケットを検索:
    #    ```
    #    /issues?set_filter=1&f[]=status_id&op[status_id]=o
    #    ```
    #
    # 2. 特定のプロジェクトの優先度が高いチケットを検索:
    #    ```
    #    /issues?set_filter=1&f[]=project_id&op[project_id]==&v[project_id][]=1&f[]=priority_id&op[priority_id]==&v[priority_id][]=4
    #    ```
    #
    # 3. 題名に特定のキーワードを含むチケットを検索:
    #    ```
    #    /issues?set_filter=1&f[]=subject&op[subject]=~&v[subject][]=keyword
    #    ```
    # Redmine 6.0では、UTF-8チェックマークパラメータ（`utf8=✓`）が削除されました。また、複数のキーワードによるAND検索や、親チケットフィルターでの複数ID指定などが可能になっています[4][5]。
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
      url = "/projects/#{project}/issues?"
      url += "utf8=%E2%9C%93&set_filter=1"

      fields.each do |field|
        field_name = field[:field_name]
        operator = field[:operator]
        value = field[:value]
        url += "&f[]=#{field_name}&op[#{field_name}]=#{operator}"
        if value.is_a?(Array)
          value.each do |v|
            url += "&v[#{field_name}][]=#{v}"
          end
        else
          url += "&v[#{field_name}][]=#{value}"
        end
      end

      date_fields.each do |field|
        field_name = field[:field_name]
        operator = field[:operator]
        value = field[:value]
        url += "&f[]=#{field_name}&op[#{field_name}]=#{operator}"
        if value.is_a?(Array)
          value.each do |v|
            url += "&v[#{field_name}][]=#{v}"
          end
        else
          url += "&v[#{field_name}][]=#{value}"
        end
      end

      time_fields.each do |field|
        field_name = field[:field_name]
        operator = field[:operator]
        value = field[:value]
        url += "&f[]=#{field_name}&op[#{field_name}]=#{operator}"
        if value.is_a?(Array)
          value.each do |v|
            url += "&v[#{field_name}][]=#{v}"
          end
        else
          url += "&v[#{field_name}][]=#{value}"
        end
      end

      number_fields.each do |field|
        field_name = field[:field_name]
        operator = field[:operator]
        value = field[:value]
        url += "&f[]=#{field_name}&op[#{field_name}]=#{operator}"
        if value.is_a?(Array)
          value.each do |v|
            url += "&v[#{field_name}][]=#{v}"
          end
        else
          url += "&v[#{field_name}][]=#{value}"
        end
      end

      text_fields.each do |field|
        field_name = field[:field_name]
        operator = field[:operator]
        value = field[:value]
        url += "&f[]=#{field_name}&op[#{field_name}]=#{operator}"
        if value.is_a?(Array)
          value.each do |v|
            url += "&v[#{field_name}][]=#{v}"
          end
        else
          url += "&v[#{field_name}][]=#{value}"
        end
      end

      status_field.each do |field|
        field_name = field[:field_name]
        operator = field[:operator]
        value = field[:value]
        url += "&f[]=#{field_name}&op[#{field_name}]=#{operator}"
        if value.is_a?(Array)
          value.each do |v|
            url += "&v[#{field_name}][]=#{v}"
          end
        else
          url += "&v[#{field_name}][]=#{value}"
        end
      end

      custom_fields.each do |field|
        field_id = field[:field_id]
        operator = field[:operator]
        value = field[:value]
        url += "&f[]=cf_#{field_id}&op[cf_#{field_id}]=#{operator}"
        url += "&v[cf_#{field_id}][]=#{value}"
      end

      url
    end

    # RedmineのURLをLLMに問い合わせて修正する
    def repair_url(url, project_id)
      messages = []
      prompt = <<-EOS
        以下はRedmineでチケットを検索するためのURLです。
        このURLの形式が正しいか検証してください。
        - 間違っている場合は、正しい形式に修正してください。
        - 正しい場合は、そのまま元のURLを返してください。
        - 修正方法がわからない場合は、そのまま元のURLを返してください。
        ** 回答にはURLの文字列のみを返してください。解説は不要です。 **
        ---
        URL: #{url}
        ---
        参考情報としてこのRedmineでチケットの項目のIDと名前の情報の一部をを以下に示します。
        #{capable_issue_properties(project_id)}
      EOS
      message = {
        role: "user",
        content: prompt,
      }
      messages << message
      response = @client.chat(
        parameters: {
          model: @model,
          messages: messages,
        },
      )
      response
    end
  end
end
