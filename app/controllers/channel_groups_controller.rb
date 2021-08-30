class ChannelGroupsController < ApplicationController
  before_action :load_channel_group, except: %i(create_from_web)
  skip_before_action :load_channel_group, only: %i(new create remove_channel)
  before_action :load_user, only: %i(new create)
  before_action :load_channel, only: %i(remove_channel)

  def show
    if @channel_group
      @channels = @channel_group.channels
        .page(params[:channels_page])
        .per_page(10)
    end
    respond_to do |format|
      format.html
      format.json { render json: @channel_group }
    end
  end

  def new
    @channel_group = @user.channel_groups.new
    respond_to do |format|
      format.html
      format.json { render json: @channel_group }
    end
  end

  def edit; end

  def create
    @channel_group = @user.channel_groups.new(channel_group_params)
    respond_to do |format|
      if @channel_group.save
        format.html do
          redirect_to @channel_group, notice: "Channel group was successfully created."
        end
        format.json { render json: @channel_group, status: :created, location: @channel_group }
      else
        format.html { render action: :new }
        format.json { render json: @channel_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @channel_group.update(channel_group_params)
        format.html do
          redirect_to @channel_group, notice: "Channel group was successfully updated."
        end
        format.json { head :no_content }
      else
        format.html { render action: :edit }
        format.json { render json: @channel_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @channel_group.destroy
    respond_to do |format|
      format.html { redirect_to user_url(@user) }
      format.json { head :no_content }
    end
  end

  # form for cloning channels that are already existing in the system
  def clone
    clonable_channels = {}
    current_user.channels.active.each do |channel|
      clonable_channels[channel.name] = channel.id
    end
    current_user.channel_groups.each do |potential_group|
      next if potential_group.id == @channel_group.id
      potential_group.channels.active.each do |potential_channel|
        next if potential_channel.user_id != current_user.id
        using_name = "#{potential_group.name}/#{potential_channel.name}"
        clonable_channels[using_name] = potential_channel.id
      end
    end
    @clonable_channels = []
    clonable_channels.keys.sort_by { |x| x[0] }.each do |key|
      @clonable_channels << [key, clonable_channels[key]]
    end
  end

  def copy
    helper = CloneChannel.new(params, @channel_group)
    helper.new_channel
    helper.clone_messages
    redirect_to channel_group_path(@channel_group), notice: "Channel copied. Please review specifically switching channel actions, as guesses are made about which channels you want to switch to."
  rescue => e
    binding.pry
    redirect_to channel_group_path(@channel_group), warn: e.message
  end

  def remove_channel
    already_member = @channel_group.channels.where(id: @channel.id).first
    notice = "Channel not currently part of this group. No changes done."

    if already_member
      @channel_group.channels.delete @channel
      @channel.destroy
      notice = "Channel removed from group."
    end

    respond_to do |format|
      format.html { redirect_to channel_group_path(@channel_group), notice: notice }
      format.json { render json: @channel_group.channels, location: [@channel_group] }
    end
  end

  def messages_report
    respond_to do |format|
      format.csv { send_data @channel_group.messages_report }
    end
  end

  def new_web_subscriber; end

  private

    def channel_group_params
      params.require(:channel_group)
        .permit(
          :description, :name, :keyword, :tparty_keyword, :default_channel_id,
          :moderator_emails, :real_time_update, :web_signup
        )
    end

    def load_user
      authenticate_user!
      @user = current_user
    end

    def load_channel_group
      authenticate_user!
      @user = current_user
      @channel_group = @user.channel_groups.find(params[:id])
      redirect_to root_url, alert: "Access Denied" unless @channel_group
    rescue ActiveRecord::RecordNotFound
      redirect_to root_url, alert: "Access Denied"
    end

    def load_channel
      authenticate_user!
      @user = current_user
      @channel_group = @user.channel_groups.find(params[:channel_group_id])
      redirect_to root_url, alert: "Access Denied" unless @channel_group
      @channel = @user.channels.find(params[:id])
      redirect_to root_url, alert: "Access Denied" unless @channel
    rescue ActiveRecord::RecordNotFound
      redirect_to root_url, alert: "Access Denied"
    end
end
