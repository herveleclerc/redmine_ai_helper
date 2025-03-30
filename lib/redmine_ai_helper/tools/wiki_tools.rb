require "redmine_ai_helper/base_tools"

module RedmineAiHelper
  module Tools
    class WikiTools < RedmineAiHelper::BaseTools
      define_function :read_wiki_page, description: "Read a wiki page from the database and return it as a JSON object. It includes the title, text, author, version, created_on, updated_on, children, parent, and attachments." do
        property :project_id, type: "integer", description: "The project ID of the wiki page to read.", required: true
        property :title, type: "string", description: "The title of the wiki page to read.", required: true
      end
      # Read an issue from the database and return it as a JSON object.
      # args: { title: "string" }
      def read_wiki_page(project_id:, title:)
        wiki = Wiki.find_by(project_id: project_id)
        raise("Wiki not found: project_id = #{project_id}") if !wiki || !wiki.visible?

        page = wiki.pages.find_by(title: title)
        raise("Page not found: title = #{title}") if !page || !page.visible?

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
          children: page.children.filter(&:visible?).map do |child|
            {
              title: child.title,
            }
          end,
          parent: page.parent ? { title: page.parent.title } : nil,
          attachements: page.attachments.map do |attachment|
            {
              filename: attachment.filename,
              filesize: attachment.filesize,
              content_type: attachment.content_type,
              description: attachment.description,
              created_on: attachment.created_on,
              attachement_url: attachment_path(attachment),
            }
          end,
        }

        tool_response(content: json)
      end

      define_function :list_wiki_pages, description: "List all wiki pages in the project. It includes the title, author, created_on, and updated_on." do
        property :project_id, type: "integer", description: "The project ID of the wiki pages to list.", required: true
      end
      # List all wiki pages in the project.
      # args: { project_id: "integer" }
      def list_wiki_pages(project_id:)
        wiki = Wiki.find_by(project_id: project_id)
        raise("Wiki not found: project_id = #{project_id}") if !wiki || !wiki.visible?
        pages = wiki.pages.filter(&:visible?)
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
        tool_response(content: json)
      end

      define_function :generate_url_for_wiki_page, description: "Generate a URL for a wiki page." do
        property :project_id, type: "integer", description: "The project ID of the wiki page to generate a URL for.", required: true
        property :title, type: "string", description: "The title of the wiki page to generate a URL for.", required: true
      end
      # Generate a URL for a wiki page.
      # args: { project_id: "integer", title: "string" }
      # returns: { url: "string" }
      def generate_url_for_wiki_page(project_id:, title:)
        wiki = Wiki.find_by(project_id: project_id)
        raise("Wiki not found: project_id = #{project_id}") if !wiki || !wiki.visible?
        page = wiki.pages.find_by(title: title)
        raise("Page not found: title = #{title}") if !page || !page.visible?
        url = "#{project_wiki_page_path(wiki.project, page.title)}"
        tool_response(content: {url: url})
      end
    end
  end
end
