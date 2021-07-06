# frozen_string_literal: true

# == Schema Information
#
# Table name: class4.lnp_databases_thinq
#
#  id       :integer(2)       not null, primary key
#  host     :string           not null
#  port     :integer(4)
#  timeout  :integer(2)       default(300), not null
#  token    :string
#  username :string
#

class Lnp::DatabaseThinq < ApplicationRecord
  self.table_name = 'class4.lnp_databases_thinq'

  has_one :lnp_database, as: :database, class_name: 'Lnp::Database'

  validates :host, presence: true
  validates :timeout, allow_nil: true, numericality: {
    greater_than: 0,
    less_than_or_equal_to: PG_MAX_SMALLINT,
    only_integer: true
  }
end
