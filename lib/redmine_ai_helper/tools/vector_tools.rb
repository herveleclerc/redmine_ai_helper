require "redmine_ai_helper/base_tools"

module RedmineAiHelper
  module Tools
    class VectorTools < RedmineAiHelper::BaseTools
      define_function :search_by_keywords, description: "Search issues from Redmine database by specified keywords. It returns the issue ID, subject, project, tracker, status, priority, author, assigned_to, description, start_date, due_date, done_ratio, is_private, estimated_hours, total_estimated_hours, spent_hours, total_spent_hours, created_on, updated_on, closed_on and issue_url." do
        property :keywords, type: "array", description: "The keywords to search for. It can be a list of keywords.", required: true do
          item type: "string", description: "The keyword to search for."
        end
        property :limit, type: "integer", description: "The number of issues to retrieve. Default is 10. Max is 50", required: false
      end

      def search_by_keywords(keywords:, limit: 10)
        raise("The vector search functionality is not enabled.") unless vector_db_enabled?
        raise("limit must be between 1 and 50.") unless limit.between?(1, 50)

        question = <<~EOS
          Search for tickets that match the following keywords.
          Keywords: #{keywords.join(", ")}}
        EOS

        search_issues(question: question, limit: limit)
      end

      define_function :search_issues, description: "Search issues from Redmine database and returns it. It returns the issue ID, subject, project, tracker, status, priority, author, assigned_to, description, start_date, due_date, done_ratio, is_private, estimated_hours, total_estimated_hours, spent_hours, total_spent_hours, created_on, updated_on, closed_on, issue_url, attachments, children and relations." do
        property :question, type: "string", description: "The question content for the issue to search for.", required: true
        property :limit, type: "integer", description: "The number of issues to retrieve. Default is 10. Max is 50", required: false
      end

      def search_issues(question:, limit: 10)
        raise("The vector search functionality is not enabled.") unless vector_db_enabled?
        raise("limit must be between 1 and 50.") unless limit.between?(1, 50)
        begin
          json_schema = {
            type: "object",
            properties: {
              issue_ids: {
                type: "array",
                items: {
                  type: "integer",
                  description: "The issue ID to read.",
                },
              },
            },
            required: ["issue_ids"],
          }
          parser = Langchain::OutputParsers::StructuredOutputParser.from_json_schema(json_schema)
          template = <<~EOS
            以下の質問に該当するチケットを検索し、IDのリストを返してください。

            質問: {question}

            {format_instructions}
          EOS
          prompt = Langchain::Prompt::PromptTemplate.new(template: template, input_variables: ["question", "format_instructions"])
          prompt_text = prompt.format(question: question, format_instructions: parser.get_format_instructions)

          llm_response = issue_vector_db.ask(question: prompt_text, k: limit)
          issue_ids_json = {}
          begin
            issue_ids_json = parser.parse(llm_response)
          rescue Langchain::OutputParsers::OutputParserException => e
            fix_parser = Langchain::OutputParsers::OutputFixingParser.from_llm(
              llm: issue_vector_db.llm,
              parser: parser,
            )
            issue_ids_json = fix_parser.parse(llm_response)
          end
          issue_ids = issue_ids_json["issue_ids"]
          return tool_response(content: []) if issue_ids.empty?
          issue_tools = RedmineAiHelper::Tools::IssueTools.new
          response = issue_tools.read_issues(issue_ids: issue_ids)
          ai_helper_logger.info("Response: #{response}")
          return response
        rescue => e
          ai_helper_logger.error("Error: #{e.message}")
          ai_helper_logger.error("Backtrace: #{e.backtrace.join("\n")}")
          raise("Error: #{e.message}")
        end
      end

      define_function :analyze_issues, description: "Analyze issues from the database using LLM for multidimensional insights." do
        property :question, type: "string", description: "The question content for the issue to analyze.", required: true
      end

      def analyze_issues(question:)
        raise("The vector search functionality is not enabled.") unless vector_db_enabled?
        issue_vector_db.ask(question: prompt_text, k: 50).chat_completion
      end

      private

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
