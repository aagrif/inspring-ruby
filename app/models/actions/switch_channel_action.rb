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

class SwitchChannelAction < Action
  include Rails.application.routes.url_helpers
  include ActionView::Helpers

  attr_reader :resume_from_last_state

  before_validation :construct_action
  validate :check_action_text

  def type_abbr
    "Switch Subscriber"
  end

  def description
    "Switch a subscriber to a new channel"
  end

  def check_action_text
    unless as_text.include? "Switch channel to"
      errors.add :as_text, "action format is invalid"
    end
  end

  def construct_action
    self.as_text = "Switch channel to #{to_channel_names.join(", ")} channel(s)"
  end

  # produces an array of selected channel names, for use in the #as_text
  # method
  def to_channel_names
    tcn = []
    Array(data["to_channel_out_group"]).each { |channel_id| tcn << channel_id }
    tcn.concat Array(data["to_channel_in_group"]) unless data["to_channel_in_group"].blank?
    channels_switched_to = Channel.where(id: tcn).to_a
    Array(channels_switched_to).map(&:name)
  end

  # teh channel ids to ADD to the subscribers passed to the
  # method
  def channel_ids_to_add
    @channel_ids_to_add ||= begin
      cids = []
      cids.concat Array(data["to_channel_in_group"]) unless data["to_channel_in_group"].blank?
      Array(data["to_channel_out_group"]).each do |acid|
        cids << acid
      end
      cids = cids.map(&:to_i).uniq
      cids
    end
  end

  # the channel ids to remove from the subscribers passed to the
  # method
  def channel_ids_to_remove
    @channel_ids_to_remove ||= begin
      cids = []
      if self.respond_to?(:message)
        cids << self.try(:message).try(:channel).try(:id)
        Array(self.message&.channel&.sibling_channel_ids).each do |cid|
          cids << cid unless channel_ids_to_add.include?(cid)
        end
      end
      cids
    end
  end

  # from_channel or channel can either be passed in
  def execute(options = {})
    Rails.logger.info "Passed in options: #{options}"
    subscribers = options[:subscribers]
    from_channel = options[:from_channel]
    channel = Array(options[:channel])

    # add the passed in parameters to the remove_from_channels ids list
    remove_from_channels = channel_ids_to_remove.dup
    if from_channel
      if from_channel.respond_to?(:id)
        remove_from_channels << from_channel.id unless from_channel.id.blank?
      else
        remove_from_channels << from_channel unless from_channel.blank?
      end
    end
    remove_from_channels = remove_from_channels.map(&:to_i).uniq

    if subscribers.blank?
      Rails.logger.warn "BadParameters SubscriberEmpty:#{subscribers.nil? || subscribers.empty?} RemoveFromChannels:#{remove_from_channels}"
      return false
    end

    if channel_ids_to_add.blank?
      Rails.logger.warn "BadParameters NoChannelsToAdd #{channel_ids_to_add}"
      return false
    end

    Rails.logger.info "Adding #{subscribers.length} to #{channel_ids_to_add.length} channels, removing from #{remove_from_channels.length} channels."

    # do the adding and removing from the channels
    subscribers.each do |subscriber|
      Rails.logger.info "Starting Subscriber: #{subscriber.id}"

      Array(remove_from_channels).each do |channel_id|
        remove_channel = Channel.where(id: channel_id).try(:first)
        if remove_channel
          Rails.logger.info "Remove Subscriber #{subscriber.id} from channel #{remove_channel.id}"
          StatsD.increment("channel.#{remove_channel.id}.subscriber_remove.#{subscriber.id}")
          remove_channel.subscribers.destroy(subscriber) rescue nil
          remove_channel.save
          ActionNotice.create caption: "Removed subscriber from channel #{remove_channel.name}", subscriber: subscriber
        end
      end

      Array(channel_ids_to_add).each do |channel_id|
        add_channel = Channel.where(id: channel_id).try(:first)
        if add_channel && !rejected_channel_type?(add_channel.type)
          StatsD.increment("channel.#{add_channel.id}.subscriber_add.#{subscriber.id}")
          subscriber.data[:resume_from_last_state] = (data[:resume_from_last_state] == "1")
          add_channel.subscribers.push subscriber
          ActionNotice.create caption: "Added subscriber to channel #{add_channel.name}", subscriber: subscriber
        end
      end

    end
    true
  end

  def rejected_channel_type?(type)
    channel_types_to_reject_subscriber_add.include?(type)
  end

  def channel_types_to_reject_subscriber_add
    %w( OnDemandMessagesChannel )
  end
end
