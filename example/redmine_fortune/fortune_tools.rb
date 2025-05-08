require "redmine_ai_helper/base_tools"

class FortuneTools < RedmineAiHelper::BaseTools
  define_function :omikuji, description: "おみくじで指定された日付の運勢を占います。" do
    property :date, type: "string", description: "占いたい日付を'YYYY-MM-DD’で指定してください", required: true
  end

  def omikuji(date:)
    ["大吉", "中吉", "小吉", "末吉", "凶", "大凶"].sample
  end

  define_function :horoscope, description: "星座占いで指定された誕生日の人の、その月の運勢を占います。" do
    property :birthday, type: "string", description: "占いたい人の誕生日を'YYYY-MM-DD'で指定してください", required: true
  end

  def horoscope(birthday:)
    fortune1 = "今月の運勢は、絶好調です。何をやっても上手くいきます。"
    fortune2 = "今月の運勢は、まずまずです。特に問題はありません。"
    fortune3 = "今月の運勢は、あまり良くありません。注意が必要です。"
    fortune4 = "今月の運勢は、最悪です。何をやっても上手くいきません。"
    [fortune1, fortune2, fortune3, fortune4].sample
  end
end
