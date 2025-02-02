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
            {
              name: "get_file_info",
              description: "Retrieve file information for the specified path and revision within the specified repository.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    repository_id: "integer",
                    path: { type: "string", description: "The path of the file to get information about." },
                    revision: { type: "string", default: "main" },
                  },
                  required: ["repository_id", "path"],
                },
              },
            },
            {
              name: "read_file",
              description: "Read a file for the specified path and revision within the specified repository.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    repository_id: "integer",
                    path: { type: "string", description: "The path of the file to read." },
                    revision: { type: "string", default: "main" },
                  },
                  required: ["repository_id", "path"],
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
        repository = Repository.find_by(id: repository_id)
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

      # Get information about a file in a repository.
      def get_file_info(args = {})
        sym_args = args.deep_symbolize_keys
        repository_id = sym_args[:repository_id]
        path = sym_args[:path]
        revision = sym_args[:revision] || "main"
        repository = Repository.find(repository_id)
        return AgentResponse.create_error("Repository not found.") if repository.nil?
        entry = repository.entry(path, revision)
        return AgentResponse.create_error("File not found: path = #{path}, revision = #{revision}") if entry.nil?
        changeset = repository.find_changeset_by_name(revision)
        author_info = nil
        if changeset
          author = changeset.author
          author_info = {
            id: author.id,
            name: author.name,
          } if author
          author_info = changeset.committer if author_info.nil?
        end
        commit_info = {
          author: author_info,
          committed_on: changeset.committed_on,
          comments: changeset.comments,
          revision: changeset.revision,

        } unless changeset.nil?
        json = {
          size: entry.size,
          type: entry.is_file? ? "file" : "directory",
          is_text: entry.is_text?,
          url_for_this_redmine: url_for(controller: "repositories", action: "entry", id: repository.project, repository_id: repository, path: path, rev: revision, only_path: true),
          commit: commit_info,
        }
        AgentResponse.create_success(json)
      end

      # Read a file in a repository.
      def read_file(args = {})
        sym_args = args.deep_symbolize_keys
        repository_id = sym_args[:repository_id]
        path = sym_args[:path]
        revision = sym_args[:revision] || "main"
        repository = Repository.find_by(id: repository_id)
        return AgentResponse.create_error("Repository not found.") if repository.nil?

        entry = repository.entry(path, revision)
        return AgentResponse.create_error("File not found: path = #{path}, revision = #{revision}") if entry.nil?

        return AgentResponse.create_error("File is not text: path = #{path}, revision = #{revision}") unless entry.is_text?

        return AgentResponse.create_error("#{path} is a directory.") if entry.is_dir?

        content = repository.cat(path, revision)
        json = {
          content: content,
          url_for_this_redmine: url_for(controller: "repositories", action: "entry", id: repository.project, repository_id: repository, path: path, rev: revision, only_path: true),
        }
        AgentResponse.create_success(json)
      end
    end
  end
end
