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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :response_action do
    response_text {Faker::Lorem.sentence}
    action
    message
  end
end
