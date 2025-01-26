require "redmine_ai_helper/base_agent"

module RedmineAiHelper
  module Agents
    class WikiAgent < RedmineAiHelper::BaseAgent
      RedmineAiHelper::BaseAgent.add_agent(name: "wiki_agent", class: self)
      def self.list_tools()
        list = {
          tools: [

            {
              name: "read_wiki_page",
              description: "Read a wiki page from the database and return it as a JSON object.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    project_id: "integer",
                    title: "string",
                  },
                  required: ["project_id", "title"],
                  description: "The title of the wiki page to read.",
                },
              },
            },
            {
              name: "list_wiki_pages",
              description: "List all wiki pages in the project.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    project_id: "integer",
                  },
                  required: ["project_id"],
                },
              },
            },
            {
              name: "generate_url_for_wiki_page",
              description: "Generate a URL for a wiki page.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    project_id: "integer",
                    title: "string",
                  },
                  required: ["project_id", "title"],
                },
              },
            },
          ],
        }
        list
      end

      # Read an issue from the database and return it as a JSON object.
      # args: { title: "string" }
      def read_wiki_page(args = {})
        sym_args = args.deep_symbolize_keys
        project_id = sym_args[:project_id]
        title = sym_args[:title]
        wiki = Wiki.find_by(project_id: project_id)
        page = wiki.pages.find_by(title: title)
        json = {
          title: page.title,
          text: page.text,
          author: {
            id: page.content.author.id,
            name: page.content.author.name,
          },
          version: page.version,
          created_on: page.created_on,
          updated_on: page.updated_on,
          children: page.children.map do |child|
            {
              title: child.title,
            }
          end,
          parent: page.parent ? { title: page.parent.title } : nil,

        }

        AgentResponse.create_success json
      end

      # List all wiki pages in the project.
      # args: { project_id: "integer" }
      def list_wiki_pages(args = {})
        sym_args = args.deep_symbolize_keys
        project_id = sym_args[:project_id]
        wiki = Wiki.find_by(project_id: project_id)
        pages = wiki.pages
        json = pages.map do |page|
          {
            title: page.title,
            author: {
              id: page.content.author.id,
              name: page.content.author.name,
            },
            created_on: page.created_on,
            updated_on: page.updated_on,
          }
        end
        AgentResponse.create_success json
      end

      # Generate a URL for a wiki page.
      # args: { project_id: "integer", title: "string" }
      # returns: { url: "string" }
      def generate_url_for_wiki_page(args = {})
        sym_args = args.deep_symbolize_keys
        project_id = sym_args[:project_id]
        title = sym_args[:title]
        wiki = Wiki.find_by(project_id: project_id)
        page = wiki.pages.find_by(title: title)
        url = "/projects/#{wiki.project.identifier}/wiki/#{page.title}"
        AgentResponse.create_success url: url
      end
    end
  end
end
