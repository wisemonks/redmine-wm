# frozen_string_literal: true

require_dependency 'issue'

module IssuePatch
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      validates :private_estimated_hours, :numericality => {:greater_than_or_equal_to => 0, :allow_nil => true, :message => :invalid}
      
      safe_attributes(
        'private_estimated_hours',
        :if => lambda {|issue, user| user.admin?})
      
      def private_estimated_hours=(h)
        write_attribute :private_estimated_hours, (h.is_a?(String) ? (h.to_hours || h) : h)
      end
    end
  end

  module ClassMethods
  end
end
