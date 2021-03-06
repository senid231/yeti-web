module RoutingTagIdsScopeable
  extend ActiveSupport::Concern

  included do

    scope :routing_tag_ids_covers, ->(*id) do
      where("yeti_ext.tag_compare(routing_tag_ids, ARRAY[#{id.join(',')}], routing_tag_mode_id)>0")
    end

    scope :tagged, ->(*value) do
      if ActiveModel::Type::Boolean.new.cast(value)
        where("routing_tag_ids <> '{}'") # has tags
      else
        where("routing_tag_ids = '{}'") # no tags
      end
    end

  end
end
