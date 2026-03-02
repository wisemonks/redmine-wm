# frozen_string_literal: true

require_dependency 'time_entry_query'

module TimeEntryQueryPatch
  def self.included(base)
    base.class_eval do
      self.available_columns << QueryAssociationColumn.new(:issue, :estimated_hours, 
        :caption => :field_estimated_hours, 
        :sortable => "#{Issue.table_name}.estimated_hours",
        :totalable => true)
      
      self.available_columns << QueryAssociationColumn.new(:issue, :private_estimated_hours, 
        :caption => :field_private_estimated_hours, 
        :sortable => "#{Issue.table_name}.private_estimated_hours",
        :totalable => true)
    end
  end
end
