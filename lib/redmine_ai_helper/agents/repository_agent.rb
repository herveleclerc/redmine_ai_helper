require "redmine_ai_helper/base_agent"

module RedmineAiHelper
  module Agents
    class RepositoryAgent < RedmineAiHelper::BaseAgent
      RedmineAiHelper::BaseAgent.add_agent(name: "repository_agent", class: self)
      def self.list_tools()
        list = {
          tools: [

            {
              name: "repository_info",
              description: "Get information about a repository.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    repository_id: "integer",
                  },
                  required: ["repository_id"],
                  description: "The ID of the repository to get information about.",
                },
              },
            },
          ],
        }
        list
      end

      # Get information about a repository.
      def repository_info(args = {})
        sym_args = args.deep_symbolize_keys
        repository_id = sym_args[:repository_id]
        repository = Repository.find(repository_id)
        return AgentResponse.create_error("Repository not found.") if repository.nil?
        json = {
          id: repository.id,
          type: repository.scm_name,
          name: repository.name,
          tags: repository.tags,
          branches: repository.branches,
          default_branch: repository.default_branch,
          url: url_for(controller: "repositories", action: "show", id: repository.project, repository_id: repository, only_path: true),
        }
        AgentResponse.create_success(json)
      end
    end
  end
end
