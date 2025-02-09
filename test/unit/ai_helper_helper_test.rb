require File.expand_path("../../test_helper", __FILE__)

class AiHelperHelperTest < ActiveSupport::TestCase
  include AiHelperHelper

  def test_md_to_html
    markdown_text = "# Hello World\nThis is a test."
    expected_html = "<h1>Hello World</h1>\n<p>This is a test.</p>"

    assert_equal expected_html, md_to_html(markdown_text)
  end

  def test_md_to_html_with_invalid_characters
    markdown_text = "# Hello World\xC2\nThis is a test."
    expected_html = "<h1>Hello World</h1>\n<p>This is a test.</p>"

    assert_equal expected_html, md_to_html(markdown_text)
  end
end
