require "langchain"

module RedmineAiHelper
  module Vector
    class VectorDb
      def initialize(llm:)
        @llm = llm
      end

      def client
        return nil unless setting.vector_search_enabled
        return @client if @client
        @client = Langchain::Vectorsearch::Qdrant.new(
          url: setting.vector_search_uri,
          api_key: setting.vector_search_api_key || "dummy",
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
        client.create_default_schema
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
        return if datas.empty?
        datas.each do |data|
          next if AiHelperVectorData.exists?(object_id: data.id, index: index_name)
          begin
            text = data_to_jsontext(data)
            uuid = SecureRandom.uuid
            vector_data = AiHelperVectorData.new(object_id: data.id, index: index_name, uuid: uuid)
            print "."
            client.add_texts(texts: [text], ids: [uuid])
            vector_data.save!
          rescue => e
            puts ""
            puts "Error: #{index_name} ##{data.id}"
            puts e.message
          end
        end
        puts ""
      end

      def ask(question:, k: 10)
        client.ask(question: question, k: k)
      end

      def data_to_jsontext(data)
        data.to_json
      end
    end
  end
end
