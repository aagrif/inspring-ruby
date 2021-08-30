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

class ResponseAction < ApplicationRecord
  acts_as_paranoid

  belongs_to :message

  has_one :action, as: :actionable
  validates_associated :action
  accepts_nested_attributes_for :action, allow_destroy: true

  def self.my_csv(options = {})
    action_columns = Action.column_names.map { |cn| "action_#{cn}" }
    CSV.generate(options) do |csv|
      csv << "#{column_names}#{action_columns}"
      find_each do |response_action|
        csv << response_action.attributes.values_at(*column_names)
        csv << response_action.action.attributes.values_at(*Action.column_names)
      end
    end
  end

  def self.import(message,file)
    csv_string = File.read(file.path).scrub
    CSV.parse(csv_string, headers: true) do |row|
      response_action = message.response_actions.find_by_id(row["id"]) || message.response_actions.new
      response_action_part = {}
      action_part = {}

      row.to_h.each do |k, v|
        if k =~ /^action_/
          attr_name = k.sub(/^action_/, "")
          action_part[attr_name] = v
        else
          response_action_part[k] = v
        end
      end

      action = response_action.build_action if response_action.action.blank?
      ["id"].each do |key|
        action_part.delete key
        response_action_part.delete key
      end

      action.attributes = action_part
      response_action.attributes = response_action_part
      response_action.message_id = message.id
      response_action.save
      action.actionable_id = response_action.id
      action.actionable_type = "ResponseAction"
      action.save
    end
  end
end
