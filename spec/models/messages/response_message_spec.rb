# == Schema Information
#
# Table name: messages
#
#  id                           :integer          not null, primary key
#  title                        :text
#  caption                      :text
#  type                         :string(255)
#  channel_id                   :integer
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  content_file_name            :string(255)
#  content_content_type         :string(255)
#  content_file_size            :integer
#  content_updated_at           :datetime
#  seq_no                       :integer
#  next_send_time               :datetime
#  primary                      :boolean
#  reminder_message_text        :text
#  reminder_delay               :integer
#  repeat_reminder_message_text :text
#  repeat_reminder_delay        :integer
#  number_of_repeat_reminders   :integer
#  options                      :text
#  deleted_at                   :datetime
#  schedule                     :text
#

require 'rails_helper'

describe ResponseMessage do
  it "has a valid factory" do
    expect(build(:response_message)).to be_valid
  end
  describe "#" do
    let(:tparty_keyword){Faker::Lorem.word}
    let(:user){create(:user)}
    let(:channel){create(:channel,tparty_keyword:tparty_keyword,user:user)}
    let(:response_message){create(:response_message,channel:channel)}
    subject {response_message}

    its(:type_abbr) {should == 'Response'}
    its(:primary) {should be_truthy}
    its(:requires_user_response?){should be_truthy}
    it "should have right value in requires_response in the db" do 
      expect(Message.find(response_message.id).requires_response).to be_truthy
    end

    describe "process_subscriber_response" do
      before do 
        @subs = create(:subscriber,user:user)
        channel.subscribers << @subs
        @to_channel = create(:channel,user:user)
        @action = create(:switch_channel_action, data: { "to_channel_in_group" => [@to_channel.id] })
        @another_action = create(:switch_channel_action, data: { "to_channel_in_group" => [create(:channel,user:user).id] })
      end

      it "finds the right response action and calls process on that action" do
        ra1 = create(:response_action,response_text:'1',message:response_message,action:@another_action)
        ra2 = create(:response_action,response_text:'2',message:response_message,action:@action)
        sr = create(:subscriber_response,message_content:'2',subscriber:@subs)
        response_message.process_subscriber_response(sr)
        expect(channel.reload.subscribers.count).to eq 0
        expect(@to_channel.reload.subscribers.count).to eq 1
        expect(@to_channel.subscribers[0]).to eq @subs
      end

      it "supports regular expression" do
        ra1 = create(:response_action,response_text:'some text',message:response_message,action:@another_action)
        ra2 = create(:response_action,response_text:'a.*',message:response_message,action:@action)
        sr = create(:subscriber_response,message_content:'a text starting with a',subscriber:@subs)
        response_message.process_subscriber_response(sr)
        expect(channel.reload.subscribers.count).to eq 0
        expect(@to_channel.reload.subscribers.count).to eq 1
        expect(@to_channel.subscribers[0]).to eq @subs
      end


      it "supports escape characters-positive" do
        ra1 = create(:response_action,response_text:'some text',message:response_message,action:@another_action)
        ra2 = create(:response_action,response_text:'\*',message:response_message,action:@action)
        sr = create(:subscriber_response,message_content:'*',subscriber:@subs)
        response_message.process_subscriber_response(sr)
        expect(channel.reload.subscribers.count).to eq 0
        expect(@to_channel.reload.subscribers.count).to eq 1
        expect(@to_channel.subscribers[0]).to eq @subs        
      end   

      it "supports escape characters-negative" do
        ra1 = create(:response_action,response_text:'some text',message:response_message,action:@another_action)
        ra2 = create(:response_action,response_text:'\*',message:response_message,action:@action)
        sr = create(:subscriber_response,message_content:'abc',subscriber:@subs)
        response_message.process_subscriber_response(sr)
        expect(channel.reload.subscribers.count).to eq 1
        expect(@to_channel.reload.subscribers.count).to eq 0
      end            

    end

    describe "grouped_responses" do
      before do 
        @subs1 = create(:subscriber,user:user)
        @subs2 = create(:subscriber,user:user)
        @subs3 = create(:subscriber,user:user)
        channel.subscribers << [@subs1, @subs2, @subs3]
        @sr1 = create(:subscriber_response,tparty_keyword:tparty_keyword,
          message_content:'Male',origin:@subs1.phone_number,message:response_message, subscriber: @subs1)
        @sr2 = create(:subscriber_response,tparty_keyword:tparty_keyword,
          message_content:'male',origin:@subs2.phone_number,message:response_message, subscriber: @subs2)
        @sr3 = create(:subscriber_response,tparty_keyword:tparty_keyword,
          message_content:'Female',origin:@subs3.phone_number,message:response_message, subscriber: @subs3)
        @sr4 = create(:subscriber_response,tparty_keyword:tparty_keyword,
          message_content:'female',origin:@subs3.phone_number,message:response_message, subscriber: @subs3)

      end
      it "returns subscriber_responses and subscribers grouped by message" do
        grouped_responses = subject.grouped_responses
        expect(grouped_responses.length).to eq 2
        if grouped_responses[0][:message_content] =~/Female$/i
          fi = 0
          mi = 1
        else
          fi = 1
          mi = 0
        end
        expect(grouped_responses[mi][:message_content]).to match /Male$/i
        expect(grouped_responses[mi][:subscriber_responses].to_a).to match_array [@sr1,@sr2]
        expect(grouped_responses[mi][:subscribers].to_a).to match_array [@subs1,@subs2]
        expect(grouped_responses[fi][:message_content]).to match /Female$/i
        expect(grouped_responses[fi][:subscriber_responses].to_a).to match_array [@sr3,@sr4]
        expect(grouped_responses[fi][:subscribers].to_a).to match_array [@subs3]
      end
    end
  end

end
