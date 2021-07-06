# frozen_string_literal: true

# == Schema Information
#
# Table name: disconnect_code
#
#  id                        :integer(4)       not null, primary key
#  code                      :integer(4)       not null
#  pass_reason_to_originator :boolean          default(FALSE), not null
#  reason                    :string           not null
#  rewrited_code             :integer(4)
#  rewrited_reason           :string
#  silently_drop             :boolean          default(FALSE), not null
#  stop_hunting              :boolean          default(TRUE), not null
#  store_cdr                 :boolean          default(TRUE), not null
#  success                   :boolean          default(FALSE), not null
#  successnozerolen          :boolean          default(FALSE), not null
#  namespace_id              :integer(4)       not null
#
# Indexes
#
#  disconnect_code_code_success_successnozerolen_idx  (code,success,successnozerolen)
#
# Foreign Keys
#
#  disconnect_code_namespace_id_fkey  (namespace_id => disconnect_code_namespace.id)
#

class DisconnectCode < ApplicationRecord
  self.table_name = 'class4.disconnect_code'

  belongs_to :namespace, class_name: 'DisconnectCodeNamespace', foreign_key: 'namespace_id'

  def display_name
    "#{namespace_id}.#{code} - #{reason}"
  end

  include WithPaperTrail

  include Yeti::TranslationReloader

  NS_TM  = 0
  NS_TS  = 1
  NS_SIP = 2
  NS_RADIUS = 3
end
