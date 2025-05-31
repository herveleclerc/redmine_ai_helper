require File.expand_path("../../../test_helper", __FILE__)

class RedmineAiHelper::Vector::QdrantTest < ActiveSupport::TestCase
  context "Qdrant" do
    setup do
      # Create a mock client and LLM
      @mock_client = mock("client")
      @mock_points = mock("points")
      @mock_llm = mock("llm")
      @mock_embedding = mock("embedding")
      @mock_llm.stubs(:embed).returns(@mock_embedding)
      @mock_embedding.stubs(:embedding).returns([0.1, 0.2, 0.3])

      # Stub Langchain::Vectorsearch::Qdrant initializer
      @qdrant = RedmineAiHelper::Vector::Qdrant.allocate
      @qdrant.instance_variable_set(:@client, @mock_client)
      @qdrant.instance_variable_set(:@llm, @mock_llm)
      @qdrant.instance_variable_set(:@index_name, "test_collection")
    end

    should "return empty array if client is nil" do
      @qdrant.instance_variable_set(:@client, nil)
      results = @qdrant.ask_with_filter(query: "test", k: 5, filter: nil)
      assert_equal [], results
    end

    should "call client.points.search with correct parameters and return payloads" do
      # Prepare mock response
      mock_response = {
        "result" => [
          { "payload" => { "id" => 1, "title" => "Issue 1" } },
          { "payload" => { "id" => 2, "title" => "Issue 2" } },
        ],
      }
      @mock_client.stubs(:points).returns(@mock_points)
      @mock_points.expects(:search).with(
        collection_name: "test_collection",
        limit: 2,
        vector: [0.1, 0.2, 0.3],
        with_payload: true,
        with_vector: true,
        filter: { foo: "bar" },
      ).returns(mock_response)

      results = @qdrant.ask_with_filter(query: "test", k: 2, filter: { foo: "bar" })
      assert_equal [{ "id" => 1, "title" => "Issue 1" }, { "id" => 2, "title" => "Issue 2" }], results
    end

    should "return empty array if result is nil" do
      @mock_client.stubs(:points).returns(@mock_points)
      @mock_points.stubs(:search).returns({ "result" => nil })
      results = @qdrant.ask_with_filter(query: "test", k: 1, filter: nil)
      assert_equal [], results
    end

    should "return empty array if result is empty" do
      @mock_client.stubs(:points).returns(@mock_points)
      @mock_points.stubs(:search).returns({ "result" => [] })
      results = @qdrant.ask_with_filter(query: "test", k: 1, filter: nil)
      assert_equal [], results
    end
  end
end
