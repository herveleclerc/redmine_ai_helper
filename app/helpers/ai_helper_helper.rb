module AiHelperHelper
  def md_to_html(text)
    pipeline = HTML::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      HTML::Pipeline::SanitizationFilter,
    ]
    pipeline.call(text)[:output].to_s.html_safe
  end
end
