module AiHelperHelper
  include Redmine::WikiFormatting::CommonMark

  def md_to_html(text)
    text = text.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    MarkdownPipeline.call(text)[:output].to_s.html_safe
  end
end
