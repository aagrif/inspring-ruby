require 'rails_helper'

describe SendMessageAction do

  it 'has a valid factory' do
    expect(build(:send_message_action)).to be_valid
  end

  it 'requires message_to_send' do
    expect(build(:send_message_action,message_to_send:nil)).to_not be_valid
  end

  it 'stores the action in as_text' do
    sc = create(:send_message_action,message_to_send:"40")
    expect(SendMessageAction.find(sc.id).as_text).to eq("Send message 40")
  end

  describe "#" do
    let(:user) {create(:user)}
    let(:ch1){create(:channel,user:user)}
    let(:msg){create(:message,channel:ch1)}
    subject {create(:send_message_action,message_to_send:msg.id)}

    its(:get_message_to_send_from_text) {should == msg.id.to_s}
    describe "virtual attribute" do
      describe "message_to_send" do
        it "returns new value if set" do
          subject.message_to_send = "33"
          expect(subject.message_to_send).to eq("33")
        end
        it "returns parsed value if not previously set" do
          subject.message_to_send = nil
          expect(subject.message_to_send).to eq(msg.id.to_s)
        end
      end            
    end
    describe "execute" do
      let(:subs){create(:subscriber,user:user)}
      let(:cmd){create(:send_message_action,message_to_send:msg.to_param)}
      it "sends the message to subscriber" do
        expect {
          allow_any_instance_of(TwilioMessagingManager).to receive(:send_message).and_return(true)
          expect(cmd.execute({subscribers:[subs]})).to be true
        }.to change{DeliveryNotice.count}.by(1)
        expect(DeliveryNotice.last.subscriber_id).to be subs.id 
        expect(DeliveryNotice.last.message_id).to be msg.id
      end
      it "returns false if message does not exist" do
        cmd1 = create(:send_message_action,message_to_send:rand(1000000))
        expect(cmd1.execute({subscribers:[subs]})).to be false
      end
    end
  end
 
end
