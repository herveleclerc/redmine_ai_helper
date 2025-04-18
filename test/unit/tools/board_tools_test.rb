require File.expand_path("../../../test_helper", __FILE__)

class BoardToolsTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :boards, :messages

  def setup
    @provider = RedmineAiHelper::Tools::BoardTools.new
    @project = Project.find(1)
    @board = @project.boards.first
    @message = @board.messages.first
  end

  def test_list_boards_success
    response = @provider.list_boards(project_id: @project.id)
    assert_equal @project.boards.count, response.size
  end

  def test_list_boards_project_not_found
    assert_raises(RuntimeError, "Project not found") do
      @provider.list_boards(project_id: 999)
    end
  end

  def test_board_info_success
    response = @provider.board_info(board_id: @board.id)
    assert_equal @board.id, response[:id]
    assert_equal @board.name, response[:name]
  end

  def test_board_info_not_found
    assert_raises(RuntimeError, "Board not found") do
      @provider.board_info(board_id: 999)
    end
  end

  def test_read_message_success
    response = @provider.read_message(message_id: @message.id)
    assert_equal @message.id, response[:id]
    assert_equal @message.content, response[:content]
  end

  def test_read_message_not_found
    assert_raises(RuntimeError, "Message not found") do
      @provider.read_message(message_id: 999)
    end
  end

  def test_generate_board_url
    response = @provider.generate_board_url(board_id: @board.id)
    assert_match(%r{boards/\d+}, response[:url])
  end

  def test_generate_board_url_no_board_id
    assert_raises(ArgumentError) do
      @provider.generate_board_url(project_id: @project.id)
    end
  end

  def test_generate_message_url_no_message_id
    assert_raises(ArgumentError) do
      @provider.generate_message_url(board_id: @board.id)
    end
  end

  def test_generate_message_url
    response = @provider.generate_message_url(message_id: @message.id)
    assert_match(%r{/boards/\d+/topics/\d+}, response[:url])
  end
end
