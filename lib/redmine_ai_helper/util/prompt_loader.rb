require "langchain"

module RedmineAiHelper
  module Util
    class PromptLoader
      class << self
        def load_template(name)
          tepmlate_base_dir = File.dirname(__FILE__) + "/../../../assets/prompt_templates"
          template_file = "#{tepmlate_base_dir}/#{name}.yml"
          Langchain::Prompt.load_from_path(file_path: template_file)
        end
      end
    end
  end
end
