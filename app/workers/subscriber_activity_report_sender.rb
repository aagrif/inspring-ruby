class SubscriberActivityReportSender
  include Sidekiq::Worker

  def self.send_hourly_report
    StatsD.increment "subscriber_activity_report_sender.hourly.perform"
    email_ch_group = group_for_report(:hourly)
    email_ch_group.each do |email, targets|
      SubscriberActivityReportMailer.hourly_subscriber_activity_report email, targets
    end
  end

  def self.send_daily_report
    StatsD.increment "subscriber_activity_report_sender.daily.perform"
    email_ch_group = group_for_report(:daily)
    email_ch_group.each do |email, targets|
      SubscriberActivityReportMailer.daily_subscriber_activity_report email, targets
    end
  end

  def self.group_for_report(frequency)
    if frequency == :hourly
      start_time = 1.hour.ago
      realtime = true
    else
      start_time = 1.day.ago
      realtime = [nil, false]
    end

    email_ch_hash = {}
    channel_ids = SubscriberActivity.where("created_at > ?", start_time)
      .distinct.pluck(:channel_id).compact
    channels = Channel.where.not(moderator_emails: [nil, ""])
      .where(id: channel_ids, real_time_update: realtime)

    channels.find_each do |ch|
      ch.moderator_emails.split(/[\s+,;]/).compact.each do |email|
        email.strip!
        email_ch_hash[email] ||= []
        email_ch_hash[email] << ch
      end
    end

    channel_group_ids = SubscriberActivity.where("created_at > ?", start_time)
      .distinct.pluck(:channel_group_id).compact
    channel_groups = ChannelGroup.where.not(moderator_emails: [nil, ""])
      .where(id: channel_group_ids, real_time_update: realtime)

    channel_groups.find_each do |ch_group|
      ch_group.moderator_emails.split(/\s+,;/).each do |email|
        email.strip!
        email_ch_hash[email] ||= []
        email_ch_hash[email] << ch_group
      end
    end

    email_ch_hash
  end

  def self.group_daily_report_by_id; end

  def perform(frequency)
    case frequency
    when :hourly then self.class.send_hourly_report
    when :daily then self.class.send_daily_report
    end
  end
end
