require "langchain"

module RedmineAiHelper
  module Vector
    class VectorDb
      attr_accessor :llm

      def initialize(llm: nil)
        @llm = llm
        @llm = RedmineAiHelper::LlmProvider.get_llm_provider.generate_client unless @llm
      end

      def client
        return nil unless setting.vector_search_enabled
        return @client if @client
        @client = RedmineAiHelper::Vector::Qdrant.new(
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
        raise NotImplementedError, "index_name method must be implemented in subclass"
      end

      def data_exists?(object_id)
        raise NotImplementedError, "data_exists? method must be implemented in subclass"
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
          vector_data = AiHelperVectorData.find_by(object_id: data.id, index: index_name)
          next if vector_data and data.updated_on < vector_data.updated_at
          begin
            add_data(vector_data: vector_data, data: data)
          rescue => e
            begin
              add_data(vector_data: vector_data, data: data, retry_flag: true)
            rescue => e
              puts ""
              puts "Error: #{index_name} ##{data.id}"
              puts e.message
            end
          end
          print "."
        end
        clean_vector_data
        puts ""
      end

      def add_data(vector_data:, data:, retry_flag: false)
        json = data_to_json(data)
        text = json[:content]
        text = text[0..1500] if retry_flag and text.length
        payload = json[:payload]
        if (vector_data)
          client.add_texts(texts: [text], ids: [vector_data.uuid], payload: payload)
          vector_data.updated_at = Time.now
        else
          uuid = SecureRandom.uuid
          vector_data = AiHelperVectorData.new(object_id: data.id, index: index_name, uuid: uuid)
          client.add_texts(texts: [text], ids: [uuid], payload: payload)
        end

        vector_data.save!
      end

      def clean_vector_data
        AiHelperVectorData.where(index: index_name).each do |vector_data|
          begin
            if data_exists?(vector_data.object_id)
              next
            end
            puts "Deleting vector data: #{index_name} ##{vector_data.object_id}"
            client.remove_texts(ids: [vector_data.uuid])
            vector_data.destroy!
            print "."
          rescue => e
            puts ""
            puts "Error: #{index_name} ##{vector_data.object_id}"
            puts e.message
            raise e
          end
        end
      end

      def similarity_search(question:, k: 10)
        client.similarity_search(query: question, k: k)
      end

      def ask(question:, k: 10)
        client.ask(question: question, k: k).chat_completion
      end

      def data_to_jsontext(data)
        data.to_json
      end
    end
  end
end
