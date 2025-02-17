require "singleton"
require "redmine_ai_helper/logger"

module RedmineAiHelper
  class BaseToolProvider
    include RedmineAiHelper::Logger
    include Rails.application.routes.url_helpers

    class << self
      def inherited(subclass)
        # puts "######## Adding provider: #{subclass.name}"
        real_class_name = subclass.name.split("::").last
        provider_list = ProviderList.instance
        provider_list.add_provider(
          real_class_name.underscore,
          subclass.name,
        )
      end

      def provider_list
        #puts "######## Getting provider list: #{ProviderList.instance.provider_list}"
        ProviderList.instance.provider_list
      end

      def provider_class_name(name)
        ProviderList.instance.provider_class_name(name)
      end

      def list_tools
        raise NotImplementedError
      end

      def provider_class_name(provider_name)
        provider = self.provider_list.find { |provider| provider[:name] == provider_name }
        provider[:class] if provider
      end
    end

    class ProviderList
      include Singleton

      def initialize
        @providers = []
      end

      def add_provider(name, class_name)
        provider = {
          name: name,
          class: class_name,
        }
        # Check if the provider is already in the list
        # If it is, remove it and add the new one
        @providers.delete_if { |a| a[:name] == name }
        @providers << provider
      end

      def provider_list
        @providers
      end
    end

  end
end
