# == Schema Information
#
# Table name: subscriber_activities
#
#  id                :integer          not null, primary key
#  subscriber_id     :integer
#  channel_id        :integer
#  message_id        :integer
#  type              :string(255)
#  origin            :string(255)
#  title             :text
#  caption           :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  channel_group_id  :integer
#  processed         :boolean
#  deleted_at        :datetime
#  tparty_identifier :string(255)
#  options           :text
#

class DeliveryNotice < SubscriberActivity
  # TODO: delete the following line when confirmed it's safe to delete.
  # attr_accessible :subscriber, :message, :channel, :channel_group

  after_initialize do |dn|
    if dn.new_record?
      begin
        dn.processed = true
      rescue ActiveModel::MissingAttributeError => e
        raise e.message
      end
    end
  end

  def self.of_primary_messages
    includes(:message).where(messages: { primary: true })
  end

  def self.of_primary_messages_that_require_response
    includes(:message).where(messages: { primary: true, requires_response: true })
  end
end
