# == Schema Information
#
# Table name: subscriptions
#
#  id            :integer          not null, primary key
#  channel_id    :integer
#  subscriber_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  deleted_at    :datetime
#

class Subscription < ApplicationRecord
  belongs_to :subscriber
  belongs_to :channel

  validates :subscriber_id, uniqueness: { scope: %i(channel_id deleted_at) }

  acts_as_paranoid
end
