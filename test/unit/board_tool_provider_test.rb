require File.expand_path("../../test_helper", __FILE__)

class BoardToolProviderTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :boards, :messages

  def setup
    @provider = RedmineAiHelper::ToolProviders::BoardToolProvider.new
    @project = Project.find(1)
    @board = @project.boards.first
    @message = @board.messages.first
  end

  def test_list_boards_success
    args = { project_id: @project.id }
    response = @provider.list_boards(args)
    assert response.is_success?
    assert_equal @project.boards.count, response.value.size
  end

  def test_list_boards_project_not_found
    args = { project_id: 999 }
    response = @provider.list_boards(args)
    assert response.is_error?
    assert_equal "Project not found", response.error
  end

  def test_board_info_success
    args = { board_id: @board.id }
    response = @provider.board_info(args)
    assert response.is_success?
    assert_equal @board.id, response.value[:id]
    assert_equal @board.name, response.value[:name]
  end

  def test_board_info_not_found
    args = { board_id: 999 }
    response = @provider.board_info(args)
    assert response.is_error?
    assert_equal "Board not found", response.error
  end

  def test_read_message_success
    args = { message_id: @message.id }
    response = @provider.read_message(args)
    assert response.is_success?
    assert_equal @message.id, response.value[:id]
    assert_equal @message.content, response.value[:content]
  end

  def test_read_message_not_found
    args = { message_id: 999 }
    response = @provider.read_message(args)
    assert response.is_error?
    assert_equal "Message not found", response.error
  end

  def test_list_tools
    tools = RedmineAiHelper::ToolProviders::BoardToolProvider.list_tools
    assert_not_nil tools
    assert_equal "list_boards", tools[:tools].first[:name]
    assert_equal "board_info", tools[:tools].second[:name]
    assert_equal "read_message", tools[:tools].third[:name]
  end

  def test_generate_board_url
    args = { project_id: @project.id, board_id: @board.id }
    response = @provider.generate_board_url(args)
    assert response.is_success?
    assert_match /boards\/\d+/, response.value[:url]
  end

  def test_generate_board_url_no_board_id
    args = { project_id: @project.id }
    response = @provider.generate_board_url(args)
    assert response.is_error?
    assert_equal "Board ID not provided", response.error
  end

  def test_generate_message_url_no_message_id
    args = { board_id: @board.id }
    response = @provider.generate_message_url(args)
    assert response.is_error?
    assert_equal "Message ID not provided", response.error
  end

  def test_generate_message_url
    args = { board_id: @board.id, message_id: @message.id }
    response = @provider.generate_message_url(args)
    assert response.is_success?
    assert_match /boards\/\d+\/topics\/\d+/, response.value[:url]
  end
end
