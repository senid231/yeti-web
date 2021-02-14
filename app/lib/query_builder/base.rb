# frozen_string_literal: true

module QueryBuilder
  class Base
    extend Forwardable

    class_attribute :logger, instance_writer: false, default: Rails.logger

    VALUE_METHODS = %i[size first last map each collect].freeze

    instance_delegate VALUE_METHODS => :to_a

    class << self
      def define_chainable(name, &block)
        define_method(name) do |*args|
          dup.perform_chainable(*args, &block)
        end

        define_method("#{name}!") do |*args|
          perform_chainable(*args, &block)
        end
      end
    end

    define_chainable :where do |conditions|
      conditions = conditions.symbolize_keys
      conditions.each { |filter_name, value| validate_filter!(filter_name, value) }
      filter_values.merge!(conditions)
    end

    define_chainable :includes do |*values|
      new_includes = values.flatten
      new_includes_nested = new_includes.extract_options!.deep_symbolize_keys
      new_includes.map!(&:to_sym)
      new_includes.each { |include_name| validate_include!(include_name, {}) }
      new_includes_nested.each { |include_name, nested_includes| validate_include!(include_name, nested_includes) }

      old_includes = include_values.dup
      old_includes_nested = old_includes.extract_options!
      simple = (old_includes + new_includes).uniq
      nested = old_includes_nested.deep_merge(new_includes_nested)
      self.include_values = simple + [nested]
    end

    define_chainable :fields do |*values|
      new_fields = values.flatten.map(&:to_sym)
      old_fields = field_values.dup

      self.field_values = [*old_fields, *new_fields].uniq
    end

    define_chainable :none do
      self.is_none = true
    end

    def initialize
      @filter_values = {}
      @include_values = []
      @is_none = false
    end

    def dup
      new_instance = self.class.new(*dup_params)
      new_instance.filter_values = filter_values.dup
      new_instance.include_values = include_values.dup
      new_instance.field_values = field_values.dup
      new_instance.sort_values = sort_values.dup
      new_instance.is_none = is_none
      new_instance
    end

    def to_a
      return @to_a if defined?(@to_a)

      @to_a = find_collection
    end

    def find(id)
      find_record(id)
    end

    def reset
      remove_instance_variable(:"@to_a")
      self
    end

    def all
      self
    end

    protected

    attr_accessor :filter_values, :include_values, :is_none, :field_values, :sort_values

    def perform_chainable(*args, &block)
      instance_exec(*args, &block)
      self
    end

    private

    def dup_params
      []
    end

    def find_record(_id)
      raise NotImplementedError, "implement #find_record method in #{self.class}"
    end

    def find_collection
      raise NotImplementedError, "implement #find_collection method in #{self.class}"
    end

    def validate_filter!(filter_name, value); end

    def validate_include!(include_name, nested_includes); end
  end
end
