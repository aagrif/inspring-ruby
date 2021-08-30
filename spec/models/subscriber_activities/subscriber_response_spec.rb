# == Schema Information
#
# Table name: subscriber_activities
#
#  id               :integer          not null, primary key
#  subscriber_id    :integer
#  channel_id       :integer
#  message_id       :integer
#  type             :string(255)
#  origin           :string(255)
#  title            :text
#  caption          :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  channel_group_id :integer
#  processed        :boolean
#  deleted_at       :datetime
#

require 'rails_helper'

describe SubscriberResponse do
  it "has a valid factory" do
    expect(build(:subscriber_response)).to be_valid
  end

  it "downcases the message before save" do
    sr = create(:subscriber_response,title:'A mixed Case STRING',caption:"Another Mixed Case STRING")
    sr.reload
    expect(sr.title).to eq 'a mixed case string'
    expect(sr.caption).to eq 'another mixed case string'
  end

  describe "#" do
    let(:tparty_keyword){Faker::Lorem.word}
    let(:keyword){Faker::Lorem.word}
    let(:true_message){Faker::Lorem.sentence}
    let(:phone_number){Faker::PhoneNumber.us_phone_number}
    let(:user){create(:user)}
    let(:subscriber){create(:subscriber,phone_number:phone_number,user:user)}
    before do
      allow_any_instance_of(TpartyKeywordValidator).to receive(:validate_each){}
      @channel = create(:channel,tparty_keyword:tparty_keyword,keyword:keyword,user:user)
      channel.subscribers << subscriber
      @subscriber_response = create(:subscriber_response,
            caption:"#{tparty_keyword} #{keyword} #{true_message}",
            origin: subscriber.phone_number)
    end
    let(:channel){@channel}
    subject {@subscriber_response}

  end

end
