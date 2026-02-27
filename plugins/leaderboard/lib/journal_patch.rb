# frozen_string_literal: true

require_dependency 'journal'

module JournalPatch
  def self.included(base)
    base.class_eval do
      def visible_details(user=User.current)
        if respond_to?(:details)
          details.reject do |detail|
            detail.prop_key == 'private_estimated_hours' && !user.admin?
          end
        else
          []
        end
      end
    end
  end
end

Journal.send(:include, JournalPatch)