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
          safe_parse(json_str)
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

      # JSON文字列を安全にパースするメソッド
      def self.safe_parse(json_string)
        begin
          return JSON.parse(json_string)
        rescue JSON::ParserError => original_error
          # パースに失敗した場合のみ補正処理を実行
          begin
            # 基本的なクリーニング
            cleaned = json_string.strip
              .gsub(/,\s*}/, '}')  # 末尾のカンマを削除
              .gsub(/,\s*]/, ']')  # 配列末尾のカンマを削除
              .gsub(/([{,]\s*)(\w+)(\s*:)/, '\1"\2"\3')  # クォートされていないキーを修正
              .gsub(/:\s*'([^']*)'/, ': "\1"')  # シングルクォートをダブルクォートに変換
              .gsub(/\t/, ' ')     # タブを空白に変換

            return JSON.parse(cleaned)
          rescue JSON::ParserError => e
            # 基本的なクリーニングでも失敗した場合、より積極的な補正を試みる
            begin
              aggressive_clean = cleaned
                .gsub(/:\s*([\w.-]+)\s*([,}])/) { ": \"#{$1}\"#{$2}" }  # クォートされていない文字列値を修正
                .gsub(/([:\[,]\s*)(\d+\.\d+|\d+)([,\}\]])/, '\1"\2"\3')  # 数値を文字列として扱う

              return JSON.parse(aggressive_clean)
            end
          end
        end
      end
    end
  end
end
