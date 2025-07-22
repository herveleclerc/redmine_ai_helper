# frozen_string_literal: true
require "langchain"
# We need to explicitly require the model file as the autoloader may not be active
# in all execution contexts (like Rake tasks).
require_relative '../../../app/models/ai_helper_setting'

module RedmineAiHelper
  module Vector
    # Langchainrb's Qdrant does not support payload filtering,
    # so it is implemented independently by inheritance
    class Qdrant < Langchain::Vectorsearch::Qdrant

      # search data from vector db with filter for payload.
      # @param query [String] The query string to search for.
      # @param filter [Hash] The filter to apply to the search.
      # @param k [Integer] The number of results to return.
      # @return [Array] An array of issues that match the query and filter.
      def ask_with_filter(query:, k: 20, filter: nil)
        return [] unless client

        embedding = llm.embed(text: query).embedding

        response = client.points.search(
          collection_name: index_name,
          limit: k,
          vector: embedding,
          with_payload: true,
          with_vector: true,
          filter: filter
        )
        results = response.dig("result")
        return [] unless results.is_a?(Array)

        results.map do |result|
          result.dig("payload")
        end
      end

      # Overriding similarity_search to support named vectors and return the correct format.
      def similarity_search(query:, k: 4)
        embedding = llm.embed(text: query).embedding

        response = client.points.search(
          collection_name: index_name,
          limit: k,
          vector: { name: "default", vector: embedding },
          with_payload: true,
          with_vector: true
        )

        # The calling code expects an array of hashes, not the raw API response.
        results = response.dig("result")
        return [] unless results.is_a?(Array)
        results
      end

      # Overriding ask to support named vectors and return the correct format.
      def ask(question:, k: 4, &block)
        embedding = llm.embed(text: question).embedding

        search_response = client.points.search(
          collection_name: index_name,
          limit: k,
          vector: embedding,
          with_payload: true,
          with_vector: true
        )

        results = search_response.dig("result")
        return "" unless results.is_a?(Array)

        context = results.map do |result|
          result.dig("payload").to_json
        end
        context = context.join("\n--\n")

        prompt = prompt_for_ask(question: question, context: context)
        llm.chat(prompt: prompt, &block)
      end

      # Overriding create_default_schema to ensure our custom create_collection method is called,
      # bypassing any potentially problematic logic in the langchain-ruby gem.
      # @return [Hash] The response from the Qdrant server.
      def create_default_schema
        create_collection(collection_name: index_name)
      end

      # Overriding create_collection to use the modern Qdrant payload structure.
      # The original method in langchain-ruby gem uses an outdated format that causes errors with recent Qdrant versions.
      # This implementation creates the collection with the correct vectors config.
      # @param collection_name [String] The name of the collection to create.
      # @return [Hash] The response from the Qdrant server.
      def create_collection(collection_name:)
        # This is the most robust way to determine the vector dimension.
        # We generate a test embedding and measure its size. This ensures the collection
        # dimension always matches the embedding model's output, regardless of configuration.
        test_embedding = llm.embed(text: "test").embedding
        dimension = test_embedding.size

        # This calls the Qdrant client from the underlying gem with the correct payload structure.
        client.collections.create(
          collection_name: collection_name,
          vectors: {
            default: {
              size: dimension,
              distance: "Cosine"
            }
          }
        )
      end

      # Overriding add_texts to support named vectors in modern Qdrant versions.
      # When a collection is created with named vectors (e.g., "default"),
      # each point's vector must be explicitly associated with that name.
      # @param texts [Array<String>] The texts to embed and add.
      # @param ids [Array] The unique IDs for each point.
      # @param payload [Hash] The payload to associate with the points.
      # @return [Hash] The response from the Qdrant server.
      def add_texts(texts:, ids:, payload: nil)
        # The Qdrant API expects an array of point objects. We construct this array.
        points = texts.each_with_index.map do |text, i|
          {
            id: ids[i],
            vector: { "default" => llm.embed(text: text).embedding },
            payload: payload
          }
        end

        client.points.upsert(
          collection_name: index_name,
          points: points
        )
      end

    end
  end
end
