require File.expand_path("../../../test_helper", __FILE__)
require "redmine_ai_helper/vector/vector_db"

class RedmineAiHelper::Vector::VectorDbTest < ActiveSupport::TestCase
  context "VectorDb" do
    setup do
      @mock_llm = mock("LLM")
      @mock_client = mock("VectorsearchClient")
      @mock_setting = mock("AiHelperSetting")
      @mock_setting.stubs(:vector_search_enabled).returns(true)
      @mock_setting.stubs(:vector_search_uri).returns("http://example.com")
      @mock_setting.stubs(:vector_search_api_key).returns("dummy_api_key")
      AiHelperSetting.stubs(:find_or_create).returns(@mock_setting)

      @vector_db = RedmineAiHelper::Vector::VectorDb.new(llm: @mock_llm)
      @vector_db.stubs(:index_name).returns("TestIndex")
      Langchain::Vectorsearch::Qdrant.stubs(:new).returns(@mock_client)
    end

    should "initialize with LLM" do
      assert_equal @mock_llm, @vector_db.llm
    end

    should "generate a client when vector search is enabled" do
      client = @vector_db.client
      assert_not_nil client
      assert_equal @mock_client, client
    end

    should "return nil client when vector search is disabled" do
      @mock_setting.stubs(:vector_search_enabled).returns(false)
      assert_nil @vector_db.client
    end

    should "generate schema using the client" do
      @mock_client.expects(:create_default_schema).once
      @vector_db.generate_schema
    end

    should "destroy schema and associated vector data" do
      AiHelperVectorData.expects(:where).with(index: "TestIndex").returns(mock("Relation").tap { |r| r.expects(:destroy_all) })
      @mock_client.expects(:destroy_default_schema).once
      @vector_db.destroy_schema
    end

    should "handle schema destruction when resource is not found" do
      @mock_client.expects(:destroy_default_schema).raises(Faraday::ResourceNotFound)
      AiHelperVectorData.expects(:where).with(index: "TestIndex").returns(mock("Relation").tap { |r| r.expects(:destroy_all) })
      assert_nothing_raised { @vector_db.destroy_schema }
    end

    should "add data to the vector database" do
      mock_data = mock("Data")
      mock_data.stubs(:id).returns(1)
      mock_data.stubs(:to_json).returns("{\"id\":1}")
      AiHelperVectorData.stubs(:exists?).with(object_id: 1, index: "TestIndex").returns(false)
      SecureRandom.stubs(:uuid).returns("test-uuid")
      AiHelperVectorData.expects(:new).with(object_id: 1, index: "TestIndex", uuid: "test-uuid").returns(mock("VectorData").tap { |vd| vd.expects(:save!) })
      @mock_client.expects(:add_texts).with(texts: ["{\"id\":1}"], ids: ["test-uuid"]).once

      @vector_db.add_datas(datas: [mock_data])
    end

    should "skip adding data if it already exists" do
      mock_data = mock("Data")
      mock_data.stubs(:id).returns(1)
      AiHelperVectorData.stubs(:exists?).with(object_id: 1, index: "TestIndex").returns(true)
      @mock_client.expects(:add_texts).never

      @vector_db.add_datas(datas: [mock_data])
    end

    should "ask a question and return a response" do
      @mock_client.expects(:ask).with(question: "What is Redmine?", k: 10).returns(mock("Response").tap { |r| r.stubs(:chat_completion).returns("Answer to the question") })
      response = @vector_db.ask(question: "What is Redmine?", k: 10)
      assert_equal "Answer to the question", response
    end
  end
end
