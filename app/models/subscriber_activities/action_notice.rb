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

class ActionNotice < SubscriberActivity
  # TODO: delete the following line when confirmed it's safe to delete.
  # attr_accessible :subscriber, :message

  after_initialize do |dn|
    if dn.new_record?
      begin
        dn.processed = true
      rescue ActiveModel::MissingAttributeError => e
        raise e.message
      end
    end
  end
end
