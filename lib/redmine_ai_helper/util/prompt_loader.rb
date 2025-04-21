# frozen_string_literal: true
require "langchain"

module RedmineAiHelper
  module Util
    # A class that loads prompt templates from YAML files.
    # The templates are stored in the assets/prompt_templates directory.
    class PromptLoader
      class << self
        # Loads a prompt template from a YAML file.
        # @param name [String] The name of the template file (without extension).
        # @return [Langchain::Prompt] The loaded prompt template.
        def load_template(name)
          tepmlate_base_dir = File.dirname(__FILE__) + "/../../../assets/prompt_templates"
          template_file = "#{tepmlate_base_dir}/#{name}.yml"
          Langchain::Prompt.load_from_path(file_path: template_file)
        end
      end
    end
  end
end
