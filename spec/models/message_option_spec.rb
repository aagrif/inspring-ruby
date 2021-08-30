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

require 'rails_helper'
