# generate git repository for Redmine AI Helper tests
namespace :redmine do
  namespace :plugins do
    namespace :ai_helper do
      namespace :vector do
        desc "Register vector data for Redmine AI Helper"
        task :regist => :environment do
          if enabled?
            puts "Registering vector data for Redmine AI Helper..."
            issues = Issue.order(:id).all
            issue_vector_db.add_datas(datas: issues)
          else
            puts "Vector search is not enabled. Skipping registration."
          end
        end

        desc "generate"
        task :generate => :environment do
          if enabled?
            puts "Generating vector index for Redmine AI Helper..."
            issue_vector_db.generate_schema
          else
            puts "Vector search is not enabled. Skipping generation."
          end
        end

        desc "Destroy vector data for Redmine AI Helper"
        task :destroy => :environment do
          if enabled?
            puts "Destroying vector data for Redmine AI Helper..."
            issue_vector_db.destroy_schema
          else
            puts "Vector search is not enabled. Skipping destruction."
          end
        end

        def issue_vector_db
          return nil unless enabled?
          return @vector_db if @vector_db
          llm = RedmineAiHelper::LlmProvider.get_llm_provider.generate_client
          @vector_db = RedmineAiHelper::Vector::IssueVectorDb.new(llm: llm)
        end

        def enabled?
          setting = AiHelperSetting.find_or_create
          setting.vector_search_enabled
        end
      end
    end
  end
end
