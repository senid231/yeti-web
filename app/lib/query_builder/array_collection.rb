# frozen_string_literal: true

module QueryBuilder
  class ArrayCollection < Base
    class_attribute :primary_key, instance_writer: false, default: :id

    def initialize(records_caller)
      @records_caller = records_caller
      super()
    end

    private

    attr_reader :records_caller

    def find_record(id)
      find_collection.detect { |record| record[:id] == id }
    end

    def find_collection
      return [] if is_none

      records = records_caller.call(filters: filter_values, includes: include_values)
    end
  end
end
