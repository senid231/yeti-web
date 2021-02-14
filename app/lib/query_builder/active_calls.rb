# frozen_string_literal: true

module QueryBuilder
  class ActiveCalls < Base
    ransack_filter :dst_country_id, type: :integer, filters: %i[eq]
    ransack_filter :dst_network_id, type: :integer, filters: %i[eq]
    ransack_filter :vendor_id, type: :integer, filters: %i[eq]
    ransack_filter :customer_id, type: :integer, filters: %i[eq]
    ransack_filter :customer_acc_id, type: :integer, filters: %i[eq]
    ransack_filter :vendor_acc_id, type: :integer, filters: %i[eq]
    ransack_filter :orig_gw_id, type: :integer, filters: %i[eq]
    ransack_filter :term_gw_id, type: :integer, filters: %i[eq]
    ransack_filter :orig_call_id, type: :integer, filters: %i[eq]
    ransack_filter :term_call_id, type: :integer, filters: %i[eq]
    ransack_filter :duration, type: :integer, filters: %i[eq gt lt]
    ransack_filter :dst_prefix_routing, type: :integer, filters: %i[start_with]
    ransack_filter :src_prefix_routing, type: :integer, filters: %i[start_with]

    request_filter :node_id, type: :integer

    private

    def fetch_data
      nodes = fetch_nodes
      return [] if nodes.empty?

      fetch_active_calls(nodes)
    end

    def fetch_active_calls(nodes)
      request_options = { only: field_values.presence, where: nil, empty_on_error: false }
      results = Parallel.map(nodes, in_threads: nodes.size) do |node|
        logger.info { "Loading active calls from Node##{node.id}" }
        begin
          rows = node.calls(request_options.dup)
          logger.info { "Loaded #{rows.size} active calls from Node##{node.id}" }
        rescue JRPC::Error => e
          logger.warn { "Error Loading #{rows.size} active calls from Node##{node.id}: <#{e.class}> #{e.message}" }
          rows = []
        end
        rows
      end
      results.flatten.map(&:deep_symbolize_keys)
    end

    def fetch_nodes
      scope = Node.all

      if filter_values.key?(:node_id)
        scope = scope.where id: filter_values[:node_id]
      end

      scope.to_a
    end

    # ============= Base class =========

    public

    class Result < SimpleDelegator
      attr_accessor :errors
    end

    FILTERS_BY_TYPE = {
      string: %i[eq equals start_with end_with contains],
      integer: %i[eq equals gt greater_than lt less_than],
      boolean: %i[eq equals]
    }.freeze
    EQ_APPLIER = ->(rows, field, value) { rows.select { |row| row[field] == value } }
    START_WITH_APPLIER = ->(rows, field, value) { rows.select { |row| row[field].start_with?(value) } }
    END_WITH_APPLIER = ->(rows, field, value) { rows.select { |row| row[field].end_with?(value) } }
    CONTAINS_APPLIER = ->(rows, field, value) { rows.select { |row| row[field].include?(value) } }
    GT_APPLIER = ->(rows, field, value) { rows.select { |row| row[field] > value } }
    LT_APPLIER = ->(rows, field, value) { rows.select { |row| row[field] < value } }
    APPLIERS = {
      eq: EQ_APPLIER,
      start_with: START_WITH_APPLIER,
      end_with: END_WITH_APPLIER,
      contains: CONTAINS_APPLIER,
      gt: GT_APPLIER,
      lt: LT_APPLIER
    }.freeze
    TYPES = {
      string: ActiveModel::Types::String.new,
      integer: ActiveModel::Types::Integer.new,
      boolean: ActiveModel::Types::Boolean.new
    }.freeze

    class_attributes :_filter_appliers, instance_writer: false, default: {}

    class << self
      def ransack_filter(name, type: nil, filters: nil)
        filters ||= FILTERS_BY_TYPE.fetch(type)
        filters.each do |suffix|
          filter_name = :"#{name}_#{suffix}"
          applier = APPLIERS.fetch(suffix)
          filter(filter_name, type: type, apply: applier)
        end
      end

      def filter(name, type: nil, apply:)
        warn "#{self.class}: filter #{name} already defined" if _filter_appliers.key?(name)
        type = TYPES.fetch(type) if type.is_a?(Symbol)

        _filter_appliers[filter_name] = lambda { |records, value|
          value = type.cast(value) unless type.nil?
          apply.call(records, name, value)
        }
      end
    end

    private

    attr_accessor :request_errors

    def find_record(id)
      find_collection.detect { |record| record[:id] == id }
    end

    def find_collection
      logger.tagged(self.class.name) do
        return [] if is_none

        self.errors = []
        records = fetch_data
        records = apply_filters(records)
        errors = self.errors
        self.errors = nil
        result = Result.new(records)
        result.errors = errors
        result
      end
    end

    # def fetch_data
    #   raise NotImplementedError
    # end
  end
end
