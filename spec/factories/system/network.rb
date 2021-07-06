# frozen_string_literal: true

# == Schema Information
#
# Table name: sys.networks
#
#  id      :integer          not null, primary key
#  name    :string           not null
#  type_id :integer          not null
#  uuid    :uuid             not null
#

FactoryBot.define do
  factory :network, class: System::Network do
    name { 'US Eagle Mobile' }
    network_type { System::NetworkType.take! }
    uuid { SecureRandom.uuid }

    trait :filled do
      prefixes { build_list :network_prefix, 2 }
    end

    trait :uniq_name do
      sequence(:name) { |n| "US Eagle Mobile #{n}" }
    end

    factory :network_full, traits: %i[filled uniq_name]
    factory :network_uniq, traits: %i[uniq_name]
  end
end
