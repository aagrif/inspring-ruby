# == Schema Information
#
# Table name: channels
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  description       :text
#  user_id           :integer
#  type              :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  keyword           :string(255)
#  tparty_keyword    :string(255)
#  next_send_time    :datetime
#  schedule          :text
#  channel_group_id  :integer
#  one_word          :string(255)
#  suffix            :string(255)
#  moderator_emails  :text
#  real_time_update  :boolean
#  deleted_at        :datetime
#  relative_schedule :boolean
#  send_only_once    :boolean          default(FALSE)
#

require 'rails_helper'

describe RandomMessagesChannel do
  its "factory works" do
    expect(build(:random_messages_channel)).to be_valid
  end
  describe "#" do
    let(:user) {create(:user)}
    let(:channel) {create(:random_messages_channel,user:user)}
    subject { channel }
    its(:has_schedule?) {should be_truthy}
    its(:sequenced?) { should be_falsey}
    its(:broadcastable?) { should be_falsey}
    its(:type_abbr){should == 'Random'}

    it "group_subscribers_by_message groups all subscribers into message bins" do
      subscribers = (0..4).map{
        subscriber = create(:subscriber,user:user)
        channel.subscribers << subscriber
        subscriber
      }
      messages = (0..6).map{
        create(:message,channel:channel)
      }
      subs=[]
      msh = subject.group_subscribers_by_message
      msh.each {|k,v|
        v.each do |sub|
          subs << sub.id
        end
        expect(v.length).to_not eq 5 #Chances of all of them getting same message during random is small
      }
      expect(subs.uniq.length).to eq 5 #All subscribers should be involved
    end

    it "send_scheduled_messages sends messages to all subscribers randomly" do
      subscribers = (0..2).map{
        subscriber = create(:subscriber,user:user)
        channel.subscribers << subscriber
        subscriber
      }
      messages = (0..3).map{
        create(:message,channel:channel)
      }
      (0..3).each do
        allow_any_instance_of(TwilioMessagingManager).to receive(:send_message).and_return(true)
        subject.send_scheduled_messages
      end
      expect(DeliveryNotice.of_subscribers(subscribers).count).to eq 12
      expect(DeliveryNotice.for_messages(messages).count).to eq 12
      expect(DeliveryNotice.of_subscriber(subscribers[0]).distinct.count).to eq 4
    end
  end
end
