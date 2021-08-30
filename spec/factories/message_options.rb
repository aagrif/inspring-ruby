# == Schema Information
#
# Table name: message_options
#
#  id         :integer          not null, primary key
#  message_id :integer
#  key        :string(255)
#  value      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :message_option do
    message_id 1
    key "MyString"
    value "MyString"
  end
end
