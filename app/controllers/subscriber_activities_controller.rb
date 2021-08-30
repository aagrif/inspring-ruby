class SubscriberActivitiesController < ApplicationController
  include SubscriberActivitiesHelper

  before_action :load_activity
  skip_before_action :load_activity, only: %i(index)
  before_action :load_activities, only: %i(index)

  def index
    if params[:unprocessed] == "true" && @subscriber_activities
      @subscriber_activities = @subscriber_activities.unprocessed
      @unprocessed = true
    end

    respond_to do |format|
      format.html
      format.json { render json: @subscriber_activities }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @subscriber_activity }
    end
  end

  def edit; end

  def update
    respond_to do |format|
      if @subscriber_activity.update(subscriber_activity_params)
        format.html do
          redirect_to sa_path(@subscriber_activity).merge(action: "show"),
                      notice: "Subscriber Activity was successfully updated."
        end
        format.json { head :no_content }
      else
        format.html { render action: :edit }
        format.json { render json: @subscriber_activity.errors, status: :unprocessable_entity }
      end
    end
  end

  private

    def subscriber_activity_params
      params.require(:subscriber_activity)
        .permit(:caption, :origin, :title, :type, :tparty_identifier, :options)
    end

    def with_ar_error_handling
      yield
    rescue ActiveRecord::RecordNotFound
    end

    def common_authentication_and_fetch
      authenticate_user!

      @user = current_user
      with_ar_error_handling { @subscriber = @user.subscribers.find(params[:subscriber_id]) }
      with_ar_error_handling { @channel = @user.channels.find(params[:channel_id]) }
      with_ar_error_handling { @channel_group = @user.channel_groups.find(params[:channel_group_id]) }
      with_ar_error_handling { @message = @channel&.messages&.find(params[:message_id]) }

      @type = params[:type]
      @klass = case @type
      when "SubscriberResponse" then SubscriberResponse
      when "DeliveryNotice" then DeliveryNotice
      else SubscriberActivity
      end
    end

    def load_activity
      common_authentication_and_fetch
      if @subscriber.nil? && @message.nil? && @channel.nil? && @channel_group.nil?
        redirect_to root_url, alert: "Access Denied"
      end

      @criteria, @target, @subscriber_activity = if @subscriber
        ["Subscriber", @subscriber, @klass.of_subscriber(@subscriber).find(params[:id])]
      elsif @message
        ["Message", @message, @klass.for_message(@message).find(params[:id])]
      elsif @channel
        ["Channel", @channel, @klass.for_channel(@channel).find(params[:id])]
      elsif @channel_group
        ["ChannelGroup", @channel_group, @klass.for_channel_group(@channel_group).find(params[:id])]
      end
    end

    def load_activities
      common_authentication_and_fetch
      if @subscriber.nil? && @message.nil? && @channel.nil? && @channel_group.nil?
        redirect_to root_url, alert: "Access Denied"
      end

      @criteria, @target, @subscriber_activities = if @subscriber
        [
          "Subscriber",
          @subscriber,
          @klass.of_subscriber(@subscriber).order(created_at: :desc)
            .page(params[:page]).per_page(10),
        ]
      elsif @message
        [
          "Message",
          @message,
          @klass.for_message(@message).order(created_at: :desc)
            .page(params[:page]).per_page(10),
        ]
      elsif @channel
        [
          "Channel",
          @channel,
          @klass.for_channel(@channel).order(created_at: :desc)
            .page(params[:page]).per_page(10),
        ]
      elsif @channel_group
        [
          "ChannelGroup",
          @channel_group,
          @klass.for_channel_group_and_its_channels(@channel_group)
            .order(created_at: :desc).page(params[:page]).per_page(10),
        ]
      end
    end
end
