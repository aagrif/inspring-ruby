# == Schema Information
#
# Table name: actions
#
#  id              :integer          not null, primary key
#  type            :string(255)
#  as_text         :text
#  deleted_at      :datetime
#  actionable_id   :integer
#  actionable_type :string(255)
#

require 'rails_helper'

describe SwitchChannelAction do

  it 'has a valid factory' do
    message = create(:message)
    action = build(:switch_channel_action)
    message.action = action
    expect(message.save).to be_truthy
  end

  describe "execute" do
    let(:user) { create(:user)                                           }
    let(:cg)   { create(:channel_group, user:user)                       }
    let(:ch1)  { create(:channel,user:user)                              }
    let(:ch2)  { create(:channel,user:user)                              }
    let(:ch3)  { create(:channel,user:user)                              }
    let(:subs) { create(:subscriber,user:user)                           }
    let(:cmd)  { create(:switch_channel_action, data: { "to_channel_in_group" => [ch2.to_param] }) }

    before do
      cg.channels << [ch1,ch2]
      ch1.subscribers << subs
    end

    it "moves a subscriber from one channel to another" do
      expect {
        expect(cmd.execute({subscribers:[subs],from_channel:ch1})).to be true
      }.to change{ ActionNotice.count }.by(2)
      expect(ch1.subscribers).to_not be_include(subs)
      expect(ch2.subscribers).to be_include(subs)
    end

    xit "returns false if subscriber or from_channel is blank" do
      expect(cmd.execute({subscribers:[],from_channel:ch1})).to be false
      expect(cmd.execute({subscribers:[subs],from_channel:nil})).to be false
    end

    # it will try to set things right
    it "returns true if subscriber is not in from_channel" do
      ch1.subscribers.delete(subs)
      expect(cmd.execute({subscribers:[subs],from_channel:ch1})).to be true
    end

    it "returns true if subscriber is already in to_channel and removes him from from_channel" do
      ch2.subscribers << subs
      ch1.subscribers << subs
      expect(ch1.subscribers).to be_include(subs)
      expect(cmd.execute({ subscribers:[subs], from_channel:ch1, message:cmd } )).to be_truthy
      expect(ch1.subscribers).to_not be_include(subs)
    end

    it "switches to multiple channels" do
      ch1.subscribers << subs
      expect(ch1.subscribers).to be_include(subs)
      cmd.data['to_channel_out_group'] = [ch2.id, ch3.id]
      expect(cmd.execute({ subscribers:[subs], from_channel:ch1, message:cmd } )).to be_truthy
      expect(ch1.subscribers).to_not be_include(subs)
      expect(ch2.subscribers).to be_include(subs)
      expect(ch3.subscribers).to be_include(subs)
    end
  end
end
