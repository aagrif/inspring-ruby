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

describe IndividuallyScheduledMessagesChannel do
  its "factory works" do
    expect(build(:individually_scheduled_messages_channel)).to be_valid
  end
  describe "#" do
    let(:user) {create(:user)}
    let(:channel) {create(:individually_scheduled_messages_channel,user:user)}
    subject {channel}
    its(:has_schedule?) {should be_falsey}
    its(:sequenced?) { should be_falsey}
    its(:broadcastable?) { should be_falsey}
    its(:type_abbr){should == 'Ind. Scheduled'}

    it "reset_next_send_time should make this channel due for send again" do
      subject.reset_next_send_time
      expect(subject.next_send_time).to be < Time.now
    end

    it "send_scheduled_messages sends messages whose next_send_time is in past" do
      m1 = create(:message,channel:channel,next_send_time:1.day.ago)
      m2 = create(:message,channel:channel,next_send_time:1.minute.ago)
      s1 = create(:subscriber,user:user)
      s2 = create(:subscriber,user:user)
      channel.subscribers << s1
      channel.subscribers << s2
      d1 = double.as_null_object
      allow(MessagingManager).to receive(:init_instance){d1}
      ma = []
      allow(d1).to receive(:broadcast_message){ |message,subscribers|
        expect(subscribers.to_a).to match_array [s1,s2]
        ma << message
      }
      subject.send_scheduled_messages
      expect(ma).to match_array [Message.find(m2.id)]
    end

    it "tmap run example" do
      Timecop.freeze(Time.zone.local(2014,1,1))
      user = create(:user)
      channel_group = create(:channel_group,user:user)
      channel = create(:individually_scheduled_messages_channel,name:'TMAP-M', user:user,
        keyword:'group1')
      channel.relative_schedule = true
      channel.save
      subscriber = create(:subscriber,user:user)
      msg0 = create(:message,channel:channel,title:'',caption:'Welcome to TMap',
        relative_schedule_type:'Minute',
        relative_schedule_number:1)
      msg1 = create(:response_message,channel:channel,title:'',caption:'Who is the designated driver',
        relative_schedule_type:'Week',
        relative_schedule_number:1,
        relative_schedule_day:'Thursday',
        relative_schedule_hour:19,
        relative_schedule_minute:0,
        reminder_message_text:'Was that message helpful?',
        repeat_reminder_message_text:'Sorry to bug you, but was it helpful?'
      )
      msg2 = create(:response_message,channel:channel,title:'',caption:'Dont let the pregame ruin the big game',
        relative_schedule_type:'Week',
        relative_schedule_number:1,
        relative_schedule_day:'Friday',
        relative_schedule_hour:19,
        relative_schedule_minute:0,
        reminder_message_text:'Was that message helpful?',
        repeat_reminder_message_text:'Sorry to bug you, but was it helpful?'        
      )
      msg3 = create(:response_message,channel:channel,title:'',caption:'The fun will be over too soon',
        relative_schedule_type:'Week',
        relative_schedule_number:1,
        relative_schedule_day:'Friday',
        relative_schedule_hour:21,
        relative_schedule_minute:0
      )
      channel.subscribers << subscriber
      Timecop.freeze(Time.zone.local(2014,1,1,1))
      allow_any_instance_of(TwilioMessagingManager).to receive(:send_message).and_return(true)
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber:subscriber).count
        }.by 1
      Timecop.freeze(Time.zone.local(2014,1,2,18,00))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to_not change{
          DeliveryNotice.where(subscriber:subscriber).count
        }
      Timecop.freeze(Time.zone.local(2014,1,2,19,00,01))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber:subscriber).count
        }.by 1
      Timecop.freeze(Time.zone.local(2014,1,2,19,01,30))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber:subscriber).count
        }.by 0
        Timecop.freeze(Time.zone.local(2014,1,2,19,30,30))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber:subscriber).count
        }.by 0         
      Timecop.freeze(Time.zone.local(2014,1,3,19,00,01))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber:subscriber).count
        }.by 1
      Timecop.freeze(Time.zone.local(2014,1,3,19,01,30))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber:subscriber).count
        }.by 0 
      #Breaks MVC, but this test case is a bit over-ambitious for a model anyway
      params={}
      params["message"]="#{channel.tparty_keyword} #{channel.keyword} yes"
      params["msisdn"]=subscriber.phone_number
      TwilioController.new.send(:handle_request,params)
      Timecop.freeze(Time.zone.local(2014,1,3,19,30,30))
      expect {
          TpartyScheduledMessageSender.new.perform
          }.to_not change{
            DeliveryNotice.where(subscriber:subscriber).count
          }
      Timecop.freeze(Time.zone.local(2014,1,3,21,00,01))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to change{
          DeliveryNotice.where(subscriber:subscriber).count
        }.by 1
      params={}
      params["message"]="#{channel.tparty_keyword} #{channel.keyword} yes"
      params["msisdn"]=subscriber.phone_number
      TwilioController.new.send(:handle_request,params)
      Timecop.freeze(Time.zone.local(2014,1,3,21,01,30))
      expect {
        TpartyScheduledMessageSender.new.perform
        }.to_not change{
          DeliveryNotice.where(subscriber:subscriber).count
        }
      Timecop.freeze(Time.zone.local(2014,1,3,21,30,30))
      expect {
          TpartyScheduledMessageSender.new.perform
          }.to_not change{
            DeliveryNotice.where(subscriber:subscriber).count
          }  
      Timecop.return        
    end

    it "is always pending_send" do
      channel.reload 
      expect(Channel.pending_send).to be_include subject
    end

  end


end
