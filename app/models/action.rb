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
#  data            :text
#

require_relative "./mixins/json_serialized_field"

class Action < ApplicationRecord
  include ActionView::Helpers
  include JSONSerializedField

  attr_writer :to_channel
  attr_writer :message_to_send

  belongs_to :actionable, polymorphic: true

  validates :type, presence: true, inclusion: {
    in: %w(SwitchChannelAction SendMessageAction),
  }

  json_serialize :data

  acts_as_paranoid

  def self.inherited(child)
    child.instance_eval do
      def model_name
        Action.model_name
      end
    end

    super
  end

  def self.child_classes
    self.validators
      .find { |v| v.attributes == [:type] && v.kind_of?(ActiveModel::Validations::InclusionValidator) }
      .options[:in]
      .map(&:constantize)
  end

  def execute(_opts = {})
    raise NotImplementedError
  end

  def type_abbr
    raise NotImplementedError
  end

  def description
    raise NotImplementedError
  end

  def to_channel
    @to_channel || get_to_channel_from_text
  end

  def get_to_channel_from_text
    if as_text
      md = as_text.match(/^Switch channel to (.+)$/)
      md[1] if md
    end
  end

  def message_to_send
    @message_to_send || get_message_to_send_from_text
  end

  def get_message_to_send_from_text
    if as_text
      md = as_text.match(/^Send message (\d+)$/)
      md[1] if md
    end
  end

  module ActiveRecordWithTypeCastSupport
    def new(*attributes, &block)
      h = attributes.first
      if h.is_a?(Hash) && !h.nil?
        type = h[:type] || h["type"]
        klass = type&.constantize
        if type && type.length > 0 && klass != self
          raise "Cast failed" unless klass <= self
          return klass.new(*attributes, &block)
        end
      end
      super *attributes, &block
    end
  end

  class << self
    prepend ActiveRecordWithTypeCastSupport
  end
end
