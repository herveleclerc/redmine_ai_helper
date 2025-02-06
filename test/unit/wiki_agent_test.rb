require File.expand_path("../../test_helper", __FILE__)

class WikiAgentTest < ActiveSupport::TestCase
  fixtures :projects, :wikis, :wiki_pages, :users

  def setup
    @agent = RedmineAiHelper::Agents::WikiAgent.new
    @project = Project.find(1)
    @wiki = @project.wiki
    @page = @wiki.pages.first
  end

  def test_read_wiki_page_success
    args = { project_id: @project.id, title: @page.title }
    response = @agent.read_wiki_page(args)
    assert response.is_success?
    assert_equal @page.title, response.value[:title]
  end

  def test_read_wiki_page_not_found
    args = { project_id: @project.id, title: "Nonexistent Page" }
    response = @agent.read_wiki_page(args)
    assert_not response.is_success?
    assert_equal "Page not found: title = Nonexistent Page", response.error
  end

  def test_list_wiki_pages
    args = { project_id: @project.id }
    response = @agent.list_wiki_pages(args)
    assert response.is_success?
    assert_equal @wiki.pages.count, response.value.size
  end

  def test_generate_url_for_wiki_page
    args = { project_id: @project.id, title: @page.title }
    response = @agent.generate_url_for_wiki_page(args)
    assert response.is_success?
    expected_url = "/projects/#{@project.identifier}/wiki/#{@page.title}"
    assert_equal expected_url, response.value[:url]
  end

  def test_list_tools
    tools = @agent.class.list_tools
    assert tools[:tools].any? { |tool| tool[:name] == "read_wiki_page" }
    assert tools[:tools].any? { |tool| tool[:name] == "list_wiki_pages" }
    assert tools[:tools].any? { |tool| tool[:name] == "generate_url_for_wiki_page" }
  end
end
