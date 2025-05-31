require File.expand_path("../../../test_helper", __FILE__)

class RedmineAiHelper::Tools::VectorToolsTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :wikis, :wiki_pages

  context "VectorTools" do
    setup do
      @vector_tools = RedmineAiHelper::Tools::VectorTools.new
      @mock_db = mock("vector_db")
      @mock_logger = mock("logger")
      @setting = mock("AiHelperSetting")
      @setting.stubs(:vector_search_enabled).returns(true)
      AiHelperSetting.stubs(:find_or_create).returns(@setting)
      @vector_tools.stubs(:ai_helper_logger).returns(@mock_logger)
      @mock_logger.stubs(:debug)
      @mock_logger.stubs(:error)
    end

    should "raise error if vector search is not enabled" do
      @setting.stubs(:vector_search_enabled).returns(false)
      assert_raises(RuntimeError, "The vector search functionality is not enabled.") do
        @vector_tools.ask_with_filter(query: "foo", k: 10, filter: {}, target: "issue")
      end
    end

    should "raise error if k is out of range" do
      assert_raises(RuntimeError, "limit must be between 1 and 50.") do
        @vector_tools.ask_with_filter(query: "foo", k: 0, filter: {}, target: "issue")
      end
      assert_raises(RuntimeError, "limit must be between 1 and 50.") do
        @vector_tools.ask_with_filter(query: "foo", k: 51, filter: {}, target: "issue")
      end
    end

    should "call vector_db and return response when target is issue" do
      @vector_tools.stubs(:vector_db).with(target: "issue").returns(@mock_db)
      @mock_db.expects(:ask_with_filter).with(query: "foo bar", k: 10, filter: {}).returns([{ "issue_id" => 1 }])
      result = @vector_tools.ask_with_filter(query: "foo bar", k: 10, filter: {}, target: "issue")
      assert_equal 1, result.first[:id]
    end

    should "call vector_db and return response when target is wiki" do
      @vector_tools.stubs(:vector_db).with(target: "wiki").returns(@mock_db)
      @mock_db.expects(:ask_with_filter).with(query: "foo bar", k: 10, filter: {}).returns([{ "wiki_id" => 1 }])
      result = @vector_tools.ask_with_filter(query: "foo bar", k: 10, filter: {}, target: "wiki")
      wiki = WikiPage.find_by(id: 1)
      assert_equal wiki.title, result.first[:title]
    end

    should "log and raise error if exception occurs" do
      @vector_tools.stubs(:vector_db).with(target: "issue").raises(StandardError.new("db error"))
      @mock_logger.expects(:error).at_least_once
      assert_raises(RuntimeError, "Error: db error") do
        @vector_tools.ask_with_filter(query: "foo", k: 10, filter: {}, target: "issue")
      end
    end

    context "#create_filter" do
      should "convert filter items with _id to integer" do
        filter = [
          { key: "project_id", condition: "match", value: "123" },
        ]
        result = @vector_tools.send(:create_filter, filter)
        assert_equal [{ key: "project_id", match: { value: 123 } }], result
      end

      should "convert filter items with other keys to string" do
        filter = [
          { key: "created_on", condition: "match", value: "2024-01-01" },
        ]
        result = @vector_tools.send(:create_filter, filter)
        assert_equal [{ key: "created_on", match: { value: "2024-01-01" } }], result
      end

      should "handle lt/lte/gt/gte conditions" do
        filter = [
          { key: "priority_id", condition: "lt", value: "5" },
        ]
        result = @vector_tools.send(:create_filter, filter)
        assert_equal [{ key: "priority_id", rante: { "lt" => 5 } }], result
      end
    end

    context "#vector_db" do
      should "return IssueVectorDb for target issue" do
        RedmineAiHelper::Vector::IssueVectorDb.expects(:new).returns(:issue_db)
        @vector_tools.instance_variable_set(:@vector_db, nil)
        assert_equal :issue_db, @vector_tools.send(:vector_db, target: "issue")
      end

      should "return WikiVectorDb for target wiki" do
        RedmineAiHelper::Vector::WikiVectorDb.expects(:new).returns(:wiki_db)
        @vector_tools.instance_variable_set(:@vector_db, nil)
        assert_equal :wiki_db, @vector_tools.send(:vector_db, target: "wiki")
      end

      should "raise error for invalid target" do
        assert_raises(RuntimeError, "Invalid target: foo. Must be 'issue' or 'wiki'.") do
          @vector_tools.send(:vector_db, target: "foo")
        end
      end
    end

    should "vector_db_enabled? returns true if setting is enabled" do
      @setting.stubs(:vector_search_enabled).returns(true)
      assert_equal true, @vector_tools.send(:vector_db_enabled?)
    end

    should "vector_db_enabled? returns false if setting is disabled" do
      @setting.stubs(:vector_search_enabled).returns(false)
      assert_equal false, @vector_tools.send(:vector_db_enabled?)
    end
  end
end
