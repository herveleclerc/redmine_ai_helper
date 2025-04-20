require "redmine_ai_helper/base_tools"

module RedmineAiHelper
  module Tools
    class VectorTools < RedmineAiHelper::BaseTools
      # define_function :search_by_keywords, description: "Search issues from Redmine database by specified keywords. It returns the issue ID, subject, project, tracker, status, priority, author, assigned_to, description, start_date, due_date, done_ratio, is_private, estimated_hours, total_estimated_hours, spent_hours, total_spent_hours, created_on, updated_on, closed_on and issue_url." do
      #   property :keywords, type: "array", description: "The keywords to search for. It can be a list of keywords.", required: true do
      #     item type: "string", description: "The keyword to search for."
      #   end
      #   property :limit, type: "integer", description: "The number of issues to retrieve. Default is 10. Max is 50", required: false
      # end

      # def search_by_keywords(keywords:, limit: 10)
      #   raise("The vector search functionality is not enabled.") unless vector_db_enabled?
      #   raise("limit must be between 1 and 50.") unless limit.between?(1, 50)

      #   question = <<~EOS
      #     Search for tickets that match the following keywords.
      #     Keywords: #{keywords.join(", ")}}
      #   EOS

      #   search_issues(question: question, limit: limit)
      # end

      # define_function :search_issues, description: "Search issues from Redmine database and returns it. It returns the issue ID, subject, project, tracker, status, priority, author, assigned_to, description, start_date, due_date, done_ratio, is_private, estimated_hours, total_estimated_hours, spent_hours, total_spent_hours, created_on, updated_on, closed_on, issue_url, attachments, children and relations." do
      #   property :question, type: "string", description: "The question content for the issue to search for.", required: true
      #   property :limit, type: "integer", description: "The number of issues to retrieve. Default is 10. Max is 50", required: false
      # end

      # def search_issues(question:, limit: 10)
      #   raise("The vector search functionality is not enabled.") unless vector_db_enabled?
      #   raise("limit must be between 1 and 50.") unless limit.between?(1, 50)
      #   begin
      #     json_schema = {
      #       type: "object",
      #       properties: {
      #         issue_ids: {
      #           type: "array",
      #           items: {
      #             type: "integer",
      #             description: "The issue ID to read.",
      #           },
      #         },
      #       },
      #       required: ["issue_ids"],
      #     }
      #     parser = Langchain::OutputParsers::StructuredOutputParser.from_json_schema(json_schema)
      #     template = <<~EOS
      #       以下の質問に該当するチケットを検索し、IDのリストを返してください。

      #       質問: {question}

      #       {format_instructions}
      #     EOS
      #     prompt = Langchain::Prompt::PromptTemplate.new(template: template, input_variables: ["question", "format_instructions"])
      #     prompt_text = prompt.format(question: question, format_instructions: parser.get_format_instructions)

      #     llm_response = issue_vector_db.ask(question: prompt_text, k: limit)
      #     issue_ids_json = {}
      #     begin
      #       issue_ids_json = parser.parse(llm_response)
      #     rescue Langchain::OutputParsers::OutputParserException => e
      #       fix_parser = Langchain::OutputParsers::OutputFixingParser.from_llm(
      #         llm: issue_vector_db.llm,
      #         parser: parser,
      #       )
      #       issue_ids_json = fix_parser.parse(llm_response)
      #     end
      #     issue_ids = issue_ids_json["issue_ids"]
      #     return [] if issue_ids.empty?
      #     issue_tools = RedmineAiHelper::Tools::IssueTools.new
      #     response = issue_tools.read_issues(issue_ids: issue_ids)
      #     ai_helper_logger.info("Response: #{response}")
      #     return response
      #   rescue => e
      #     ai_helper_logger.error("Error: #{e.message}")
      #     ai_helper_logger.error("Backtrace: #{e.backtrace.join("\n")}")
      #     raise("Error: #{e.message}")
      #   end
      # end

      # define_function :analyze_issues, description: "Analyze issues from the database using LLM for multidimensional insights." do
      #   property :question, type: "string", description: "The question content for the issue to analyze.", required: true
      # end

      # def analyze_issues(question:)
      #   raise("The vector search functionality is not enabled.") unless vector_db_enabled?
      #   issue_vector_db.ask(question: prompt_text, k: 50).chat_completion
      # end

      define_function :ask_with_filter, description: "Ask to vector databse with a query words and filter." do
        property :query_words, type: "array", description: "The words to use for vector search.", required: true do
          item type: "string", description: "The word to use for vector search."
        end
        property :k, type: "integer", description: "The number of issues to retrieve. Default is 10. Max is 50", required: false
        property :filter, type: "object", description: "The filter to apply to the question.", required: true do
          property :must, type: "array", description: "The must filter. All conditions must be met. AND condition.", required: false do
            item :filter_item, type: "object", description: "The filter item.", required: true do
              item :key, type: "string", description: "The key to filter.", required: true, enum: ["project_id", "tracker_id", "status_id", "priority_id", "author_id", "assigned_to_id", "created_on", "updated_on", "due_date", "version_id"]
              item :condition, type: "string", description: "The condition to filter. 'match' means exact match, 'lt' means less than, 'lte' means less than or equal to, 'gt' means greater than, 'gte' means greater than or equal to.", required: true, enum: ["match", "lt", "lte", "gt", "gte"]
              item :value, type: "string", description: "The value to filter. The value must be a string.", required: true
            end
          end
          property :should, type: "array", description: "At least one condition must be met. OR condition.", required: false do
            item :filter_item, type: "object", description: "The filter item.", required: true do
              item :key, type: "string", description: "The key to filter.", required: true, enum: ["project_id", "tracker_id", "status_id", "priority_id", "author_id", "assigned_to_id", "created_on", "updated_on", "due_date", "version_id"]
              item :condition, type: "string", description: "The condition to filter. 'match' means exact match, 'lt' means less than, 'lte' means less than or equal to, 'gt' means greater than, 'gte' means greater than or equal to.", required: true, enum: ["match", "lt", "lte", "gt", "gte"]
              item :value, type: "string", description: "The value to filter. The value must be a string.", required: true
            end
          end
          property :must_not, type: "array", description: "None of the conditions must be met. NOT operation. ", required: false do
            item :filter_item, type: "object", description: "The filter item.", required: true do
              item :key, type: "string", description: "The key to filter.", required: true, enum: ["project_id", "tracker_id", "status_id", "priority_id", "author_id", "assigned_to_id", "created_on", "updated_on", "due_date", "version_id"]
              item :condition, type: "string", description: "The condition to filter. 'match' means exact match, 'lt' means less than, 'lte' means less than or equal to, 'gt' means greater than, 'gte' means greater than or equal to.", required: true, enum: ["match", "lt", "lte", "gt", "gte"]
              item :value, type: "string", description: "The value to filter. The value must be a string.", required: true
            end
          end
        end
      end

      def ask_with_filter(query_words:, k: 10, filter: {})
        raise("The vector search functionality is not enabled.") unless vector_db_enabled?
        raise("limit must be between 1 and 50.") unless k.between?(1, 50)

        begin
          filter_json = {}
          filter_json[:must] = create_filter(filter[:must]) if filter[:must]
          filter_json[:should] = create_filter(filter[:should]) if filter[:should]
          filter_json[:must_not] = create_filter(filter[:must_not]) if filter[:must_not]

          response = issue_vector_db.ask_with_filter(query: query_words.join(" "), k: k, filter: filter_json)
          ai_helper_logger.info("Response: #{response}")
          response
        rescue => e
          ai_helper_logger.error("Error: #{e.message}")
          ai_helper_logger.error("Backtrace: #{e.backtrace.join("\n")}")
          raise("Error: #{e.message}")
        end
      end

      private

      def create_filter(filter)
        filter_json = []
        filter.each do |f|
          item = {}
          value = f[:value]
          value = f[:value].to_i if f[:key].end_with?("_id")
          item[:key] = f[:key]
          case f[:condition]
          when "match"
            item[:match] = { value: value }
          when "lt", "lte", "gt", "gte"
            item[:rante] = {
              f[:condition] => value,
            }
          end

          filter_json << item
        end

        filter_json
      end

      def vector_db_enabled?
        setting = AiHelperSetting.find_or_create
        setting.vector_search_enabled
      end

      def issue_vector_db
        @vector_db ||= RedmineAiHelper::Vector::IssueVectorDb.new
      end
    end
  end
end
