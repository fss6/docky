# frozen_string_literal: true

# == Schema Information
#
# Table name: collection_delivery_events
#
#  id                     :bigint           not null, primary key
#  event                  :string           not null
#  occurred_at            :datetime         not null
#  raw_payload            :jsonb            not null
#  reliability_tier       :string           default("strong"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  collection_dispatch_id :bigint           not null
#
# Indexes
#
#  index_collection_delivery_events_on_collection_dispatch_id  (collection_dispatch_id)
#  index_collection_delivery_events_on_dispatch_event          (collection_dispatch_id,event,occurred_at)
#
# Foreign Keys
#
#  fk_rails_...  (collection_dispatch_id => collection_dispatches.id)
#
class CollectionDeliveryEvent < ApplicationRecord
  belongs_to :collection_dispatch

  enum :reliability_tier, {
    strong: "strong",
    weak: "weak"
  }, default: :strong, prefix: true

  validates :event, presence: true
  validates :occurred_at, presence: true
end
