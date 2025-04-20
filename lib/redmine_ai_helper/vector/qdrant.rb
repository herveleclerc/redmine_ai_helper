require "langchain"

module RedmineAiHelper
  module Vector
    class Qdrant < Langchain::Vectorsearch::Qdrant
      def ask_with_filter(query:, k: 20, filter: nil)
        return [] unless client

        embedding = llm.embed(text: query).embedding

        response = client.points.search(
          collection_name: index_name,
          limit: k,
          vector: embedding,
          with_payload: true,
          with_vector: true,
          filter: filter,
        )
        response.dig("result").map do |result|
          result.dig("payload").to_s
        end
      end
    end
  end
end
