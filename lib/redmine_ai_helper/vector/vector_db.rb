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
        AiHelperVectorData.where(index: index_name).destroy_all
      end

      def add_datas(datas:)
        texts = []
        uuids = []
        vector_datas = []
        return if datas.empty?
        datas.each do |data|
          next if AiHelperVectorData.exists?(object_id: data.id, index: index_name)
          text = data_to_jsontext(data)
          uuid = SecureRandom.uuid
          texts << text
          uuids << uuid
          vector_datas << AiHelperVectorData.new(object_id: data.id, index: index_name, uuid: uuid)
          print "."
          if texts.size >= 100
            client.add_texts(texts: texts, ids: uuids)
            texts = []
          end
          vector_datas.each { |v| v.save! }

          vector_datas = []
        end
        unless texts.empty?
          client.add_texts(texts: texts, ids: uuids)
          vector_datas.each { |v| v.save! }
        end
        puts ""
      end

      def data_to_jsontext(data)
        data.to_json
      end
    end
  end
end
