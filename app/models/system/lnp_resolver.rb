# frozen_string_literal: true

# == Schema Information
#
# Table name: sys.lnp_resolvers
#
#  id      :integer(4)       not null, primary key
#  address :string           not null
#  name    :string           not null
#  port    :integer(4)       not null
#
# Indexes
#
#  lnp_resolvers_name_key  (name) UNIQUE
#

class System::LnpResolver < ApplicationRecord
  self.table_name = 'sys.lnp_resolvers'
  validates :name, uniqueness: true
  validates :name, :address, :port, presence: true

  include WithPaperTrail

  def display_name
    name.to_s
  end
end
