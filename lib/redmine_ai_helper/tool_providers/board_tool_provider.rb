require "redmine_ai_helper/base_tool_provider"

module RedmineAiHelper
  module ToolProviders
    class BoardToolProvider < RedmineAiHelper::BaseToolProvider
      # List all tools provided by this tool provider.
      def self.list_tools()
        list = {
          tools: [
            {
              name: "list_boards",
              description: "List all boards in the project. It returns the board ID, project ID, name, description, messages_count, and last_message.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    project_id: {
                      type: "integer"
                    },
                  },
                  required: ["project_id"],
                },
              },
            },
            {
              name: "board_info",
              description: "Read a board from the database and return it as a JSON object. It returns the board ID, project ID, name, description, messages_count, and messages.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    board_id: {
                      type: "integer"
                    },
                  },
                  required: ["board_id"],
                },
              },
            },
            {
              name: "read_message",
              description: "Read a message from the database and return it as a JSON object. It returns the message ID, board ID, parent_id, subject, content, author,  created_on, updated_on, and replies.",
              arguments: {
                schema: {
                  type: "object",
                  properties: {
                    message_id: {
                      type: "integer"
                    },
                  },
                  required: ["message_id"],
                },
              },
            }
          ]
        }
        list
      end

      # List all boards in the project.
      # args: { project_id: "integer" }
      def list_boards(args = {})
        sym_args = args.symbolize_keys
        project_id = sym_args[:project_id]
        project = Project.find_by(id: project_id)
        return ToolResponse.create_error("Project not found") if project.nil?
        boards = project.boards.filter{|b| b.visible?}
        board_list = []
        boards.each do |board|
          board_list << {
            id: board.id,
            name: board.name,
            description: board.description,
            messages_count: board.messages_count,
            parent_board_id: board.parent_id
          }
        end
        ToolResponse.create_success(board_list)
      end

      # Read a board from the database and return it as a JSON object.
      # args: { board_id: "integer" }
      def board_info(args = {})
        sym_args = args.symbolize_keys
        board_id = sym_args[:board_id]
        board = Board.find_by(id: board_id)
        return ToolResponse.create_error("Board not found") if board.nil?
        board_hash = {
          id: board.id,
          project_id: board.project_id,
          name: board.name,
          description: board.description,
          messages: board.messages.filter{|m| m.visible? }.map do |message|
            hash ={
              id: message.id,
              content: message.content,
              created_on: message.created_on,
            }
            hash[:authro] = {
              id: message.author.id,
              name: message.author.name,
            } if message.author
            hash
          end,
        }
        ToolResponse.create_success(board_hash)
      end

      # Read a message from the database and return it as a JSON object.
      # args: { message_id: "integer" }
      def read_message(args = {})
        sym_args = args.symbolize_keys
        message_id = sym_args[:message_id]
        message = Message.find_by(id: message_id)
        return ToolResponse.create_error("Message not found") if message.nil? || !message.visible?
        message_hash = {
          id: message.id,
          board_id: message.board_id,
          parent_id: message.parent_id,
          subject: message.subject,
          content: message.content,
          author: {
            id: message.author.id,
            name: message.author.name,
          },
          created_on: message.created_on,
          updated_on: message.updated_on,
          replies: message.children.filter(&:visible?).map do |reply|
            {
              id: reply.id,
              content: reply.content,
              author: {
                id: reply.author.id,
                name: reply.author.name,
              },
              created_on: reply.created_on,
              updated_on: reply.updated_on,
            }
          end,
        }

        ToolResponse.create_success(message_hash)
      end
    end
  end
end
