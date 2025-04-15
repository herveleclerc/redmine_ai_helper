require "langchain"

module RedmineAiHelper
  module Vector
    class VectorDb
      def initialize(llm:)
        @llm = llm
      end

      def client
        return nil unless setting.vector_search_enabled
        @client ||= Langchain::Vectorsearch::Weaviate.new(
          url: setting.vector_search_uri,
          api_key: setting.vector_search_api_key,
          index_name: index_name,
          llm: @llm,
        )
        @client
      end

      def setting
        @setting ||= AiHelperSetting.find_or_create
      end

      def index_name
        nil
      end

      def generate_schema
        begin
          @default_scehma ||= client.get_default_schema
        rescue Faraday::ResourceNotFound
          @default_schema = client.create_default_schema
        end
      end

      def destroy_schema
        begin
          client.destroy_default_schema
        rescue Faraday::ResourceNotFound
          # do nothing
        end
      end

      def add_datas(datas:)
        texts = []
        uuids = []
        return if datas.empty?
        datas.each do |data|
          text = data_to_jsontext(data)
          uuid = SecureRandom.uuid
          texts << text
          uuids << uuid
          print "."
          if texts.size >= 100
            client.add_texts(texts: texts, ids: uuids)
            texts = []
            uuids = []
          end
        end
        client.add_texts(texts: texts, ids: uuids)
        puts ""
      end

      def data_to_jsontext(data)
        data.to_json
      end
    end
  end
end
