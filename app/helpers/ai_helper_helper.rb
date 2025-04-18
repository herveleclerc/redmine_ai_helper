module AiHelperHelper
  include Redmine::WikiFormatting::CommonMark

  # Change the text from markdown to HTML
  # @param text [String] The text to be converted
  # @return [String] The converted HTML text
  def md_to_html(text)
    text = text.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    MarkdownPipeline.call(text)[:output].to_s.html_safe
  end
end
