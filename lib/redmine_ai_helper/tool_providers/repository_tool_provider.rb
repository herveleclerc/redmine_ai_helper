require "redmine_ai_helper/base_tool_provider"

module RedmineAiHelper
  module ToolProviders
    class RepositoryToolProvider < RedmineAiHelper::BaseToolProvider
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
              name: "get_revision_info",
              description: "Get information about a revision in a repository. Returns the author, committed_on, list of path, and comments for the revision.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    repository_id: "integer",
                    revision: {
                      type: "string",
                      description: "The revision to get information about."
                    },
                  },
                  required: ["repository_id", "revision"],
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
            {
              name: "read_diff",
              description: "Get the diff information for a specified path and revision within the repository. If the path is not specified, the diff information for all files in the revision is returned. If the revision_to is specified, the diff information between the two revisions is returned.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    repository_id: "integer",
                    path: { type: "string", description: "The path of the file to get diff information about." },
                    revision: {
                      type: "string",
                      description: "The revision to get diff information about.",
                    },
                    revision_to: {
                      type: "string",
                      description: "The revision to compare the diff against.",
                    }
                  },
                  required: ["repository_id", "revision"],
                },
              },
            }
          ],
        }
        list
      end

      # Get information about a repository.
      def repository_info(args = {})
        sym_args = args.deep_symbolize_keys
        repository_id = sym_args[:repository_id]
        repository = Repository.find_by(id: repository_id)
        return ToolResponse.create_error("Repository not found.") if repository.nil?
        json = {
          id: repository.id,
          type: repository.scm_name,
          name: repository.name,
          tags: repository.tags,
          branches: repository.branches,
          default_branch: repository.default_branch,
          url: url_for(controller: "repositories", action: "show", id: repository.project, repository_id: repository, only_path: true),
        }
        ToolResponse.create_success(json)
      end

      # Get information about a revision in a repository.
      # Returns the author, committed_on, list of path, and comments for the revision.
      def get_revision_info(args = {})
        sym_args = args.deep_symbolize_keys
        repository_id = sym_args[:repository_id]
        revision = sym_args[:revision]
        repository = Repository.find_by_id(repository_id)
        return ToolResponse.create_error("Repository not found: repository_id = #{repository_id}") if repository.nil?
        changeset = repository.find_changeset_by_name(revision)
        return ToolResponse.create_error("Revision not found: revision = #{revision}") if changeset.nil?
        user = changeset.user
        author_info = {
            id: user.id,
            name: user.name,
        } if user
        author_info = changeset.author if author_info.nil?
        revision_info = {
          repository_id: repository_id,
          author: author_info,
          committed_on: changeset.committed_on,
          paths: changeset.filechanges.map{|f| f.path},
          comments: changeset.comments,
          revision: changeset.revision,
        }
        ToolResponse.create_success(revision_info)
      end

      # Get information about a file in a repository.
      def get_file_info(args = {})
        sym_args = args.deep_symbolize_keys
        repository_id = sym_args[:repository_id]
        path = sym_args[:path]
        revision = sym_args[:revision] || "main"
        repository = Repository.find(repository_id)
        return ToolResponse.create_error("Repository not found.") if repository.nil?
        entry = repository.entry(path, revision)
        return ToolResponse.create_error("File not found: path = #{path}, revision = #{revision}") if entry.nil?
        changeset = repository.find_changeset_by_name(revision)
        author_info = nil
        if changeset
          user = changeset.user
          author_info = {
            id: user.id,
            name: user.name,
          } if user
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
        ToolResponse.create_success(json)
      end

      # Read a file in a repository.
      def read_file(args = {})
        sym_args = args.deep_symbolize_keys
        repository_id = sym_args[:repository_id]
        path = sym_args[:path]
        revision = sym_args[:revision] || "main"
        repository = Repository.find_by(id: repository_id)
        return ToolResponse.create_error("Repository not found.") if repository.nil?

        entry = repository.entry(path, revision)
        return ToolResponse.create_error("File not found: path = #{path}, revision = #{revision}") if entry.nil?

        return ToolResponse.create_error("File is not text: path = #{path}, revision = #{revision}") unless entry.is_text?

        return ToolResponse.create_error("#{path} is a directory.") if entry.is_dir?

        content = repository.cat(path, revision)
        json = {
          content: content,
          url_for_this_redmine: url_for(controller: "repositories", action: "entry", id: repository.project, repository_id: repository, path: path, rev: revision, only_path: true),
        }
        ToolResponse.create_success(json)
      end

      # Get the diff information for a specified path and revision within the repository.
      # If the path is not specified, the diff information for all files in the revision is returned.
      def read_diff(args = {})
        sym_args = args.deep_symbolize_keys
        repository_id = sym_args[:repository_id]
        path = sym_args[:path]
        revision = sym_args[:revision]
        revision_to = sym_args[:revision_to]
        repository = Repository.find(repository_id)
        return ToolResponse.create_error("Repository not found.") if repository.nil?

        changeset = repository.find_changeset_by_name(revision)
        return ToolResponse.create_error("Revision not found: revision = #{revision}") if changeset.nil?

        diff_lines = repository.diff(path, revision, revision_to)

        diff_text = diff_lines.join("\n")
        diff_text.force_encoding("UTF-8")

        json = {
          repository_id: repository_id,
          revision: revision,
          diff: diff_text,
        }

        ToolResponse.create_success(json)
      end
    end
  end
end
