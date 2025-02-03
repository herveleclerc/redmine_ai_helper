module RedmineAiHelper
  module Util
    class JsonExtractor
      include RedmineAiHelper::Logger
      def self.extract(input)
        # パターン1: 純粋なJSONテキスト
        # パターン2: Markdownのコードブロックで囲まれたJSON

        # Markdownのコードブロックを処理
        if input.start_with?("```json") && input.end_with?("```")
          # ```json と ``` を削除
          json_str = input.gsub(/^```json\n/, "").gsub(/```$/, "")
        else
          # 純粋なJSONテキストとして扱う
          json_str = input
        end

        # JSONとして解析できるか確認
        begin
          # 文字列からRubyのハッシュに変換
          JSON.parse(json_str)
        rescue JSON::ParserError => e
          ai_helper_logger.error "Invalid JSON format: #{e.full_message}: \n###original json\n #{json_str}\n###"
          raise "Invalid JSON format: #{e.message}: \n###original json\n #{json_str}\n###"
        end
      end

      # 文字列として整形されたJSONを取得するメソッド
      def self.extract_pretty(input)
        hash = extract(input)
        JSON.pretty_generate(hash)
      end
    end
  end
end