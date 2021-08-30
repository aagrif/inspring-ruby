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

class SubscriberResponse < SubscriberActivity
  before_validation :case_convert_message

  def target
    if channel_group
      channel_group
    elsif channel
      channel
    end
  end

  def content_text
    caption
  end

  def try_processing
    return false unless target&.process_subscriber_response(self)
    self.processed = true
    save
    true
  end

  private

    def case_convert_message
      self.caption = caption&.downcase
      self.title = title&.downcase
    end
end
