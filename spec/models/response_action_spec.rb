# == Schema Information
#
# Table name: response_actions
#
#  id            :integer          not null, primary key
#  response_text :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  message_id    :integer
#  deleted_at    :datetime
#

require 'rails_helper'

describe ResponseAction do
  it "factory works" do
    expect(build(:response_action)).to be_valid
  end
  
end
