# frozen_string_literal: true

module RedmineAiHelper
  module UserPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval do
        has_many :ai_helper_conversations, class_name: "AiHelperConversation", dependent: :destroy
      end
    end

    module ClassMethods
    end
  end
end

unless User.included_modules.include?(RedmineAiHelper::UserPatch)
  User.send(:include, RedmineAiHelper::UserPatch)
end