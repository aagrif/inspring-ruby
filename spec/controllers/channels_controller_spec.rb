require 'rails_helper'

describe ChannelsController do
  let(:user) {FactoryGirl.create(:user)}
  let(:valid_attributes) { attributes_for(:announcements_channel)}

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "guest user" do
    it "is redirected to signup form always and not allowed to alter db" do
      channel = user.channels.create! valid_attributes

      get :index,params: {}
      expect(response).to redirect_to new_user_session_path

      get :new, params: {}
      expect(response).to redirect_to new_user_session_path

      get :show, params: {:id => channel.to_param}
      expect(response).to redirect_to new_user_session_path

      get :messages_report, params: {:id => channel.to_param}
      expect(response).to redirect_to new_user_session_path

      get :edit, params: {:id => channel.to_param}
      expect(response).to redirect_to new_user_session_path

      expect {
            post :create, params: {:channel => valid_attributes}
          }.to_not change(Channel, :count)

      expect_any_instance_of(Channel).to_not receive(:update)
      patch :update, params: {:id => channel.to_param, :channel => { "name" => "MyString" }}

      expect {
          delete :destroy, params: {:id => channel.to_param}
      }.to_not change(Channel, :count)

      get :list_subscribers, params: {:id => channel.to_param}
      expect(response).to redirect_to new_user_session_path

      subscriber = create(:subscriber,user:user)
      expect {
        post :add_subscriber, params: {channel_id:channel.to_param, id:subscriber.to_param }
      }.to_not change(channel.subscribers, :count)

      subscriber = create(:subscriber,user:user)
      channel.subscribers << subscriber
      expect {
        post :remove_subscriber, params: {channel_id:channel.to_param, id:subscriber.to_param }
      }.to_not change(channel.subscribers, :count)

    end
  end

  describe "one user" do
    it "cannot access other user channels" do
      channel = user.channels.create! valid_attributes
      another_user = create(:user)
      sign_in another_user

      get :show, params: {:id => channel.to_param}
      expect(response).to redirect_to root_url

      get :messages_report, params: {:id => channel.to_param}
      expect(response).to redirect_to root_url      

      get :edit, params: {:id => channel.to_param}
      expect(response).to redirect_to root_url

      expect_any_instance_of(Channel).to_not receive(:update)
      patch :update, params: {:id => channel.to_param, :channel => { "name" => "MyString" }}

      expect {
          delete :destroy, params: {:id => channel.to_param}
      }.to_not change(Channel, :count)
      
      get :list_subscribers, params: {:id => channel.to_param}
      expect(response).to redirect_to root_url

      subscriber = create(:subscriber,user:user)
      expect {
        post :add_subscriber, params: {channel_id:channel.to_param, id:subscriber.to_param }
      }.to_not change(channel.subscribers, :count)

      subscriber = create(:subscriber,user:user)
      channel.subscribers << subscriber
      expect {
        post :remove_subscriber, params: {channel_id:channel.to_param, id:subscriber.to_param }
      }.to_not change(channel.subscribers, :count)

    end
  end
  describe "valid user" do
    before do
      sign_in(user)
    end
    describe "GET index" do
      before do
        @channels = (0..2).map{create(:channel,user:user)}
        @channels = Channel.find(@channels.map(&:id))
        @channel_group = create(:channel_group,user:user)        
      end
      it "assigns channels and channel_groups" do
        get :index, params: {}
        expect(assigns(:channels)).to match_array(@channels)
        expect(assigns(:channel_groups)).to match_array([@channel_group])
      end
      it "does not list channels part of group in @channels" do
        @channel_group.channels << @channels[1]
        get :index, params: {}
        expect(assigns(:channels)).to match_array([@channels[0],@channels[2]])
        expect(assigns(:channel_groups)).to match_array([@channel_group])
      end
    end 
    describe "GET show" do
      it "assigns the requested channel as @channel" do
        channel = user.channels.create! valid_attributes
        channel = user.channels.find(channel.id)
        subscribers = (0..2).map {create(:subscriber,user:user)}
        channel.subscribers << subscribers
        get :show, params: {user_id:user.to_param, :id => channel.to_param}
        expect(assigns(:channel)).to eq(channel)
        expect(assigns(:subscribers)).to match_array(subscribers)
      end
    end    
    describe "GET new" do
      it "assigns a new channel as @channel" do
        get :new, params: {user_id:user.to_param}
        expect(assigns(:channel)).to be_a_new(Channel)
      end
    end
    describe "GET edit" do
      it "assigns the requested channel as @channel" do
        channel = user.channels.create! valid_attributes
        channel = Channel.find(channel.id)
        get :edit, params: {user_id:user.to_param,:id => channel.to_param}
        expect(assigns(:channel)).to eq(channel)
      end
    end
    describe "POST create" do
      describe "with valid params" do
        it "creates a new Channel" do
          expect {
            post :create, params: {:channel => valid_attributes}
          }.to change(Channel, :count).by(1)
        end

        it "assigns a newly created channel as @channel" do
          post :create, params: {:channel => valid_attributes}
          expect(assigns(:channel)).to be_a(Channel)
          expect(assigns(:channel)).to be_persisted
        end

        it "redirects to the created channel" do
          post :create, params: {user_id:user.to_param,:channel => valid_attributes}
          expect(response).to redirect_to(Channel.last)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved channel as @channel" do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Channel).to receive(:save).and_return(false)
          post :create, params: {user_id:user.to_param, :channel => { "name" => "invalid value" }}
          expect(assigns(:channel)).to be_a_new(Channel)
        end

        it "re-renders the 'new' template" do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Channel).to receive(:save).and_return(false)
          post :create, params: {user_id:user.to_param, :channel => { "name" => "invalid value" }}
          expect(response).to render_template("new")
        end
      end
    end   
    describe "PATCH update" do
      describe "with valid params" do
        it "updates the requested channel" do
          channel = user.channels.create! valid_attributes
          # Assuming there are no other channels in the database, this
          # specifies that the Channel created on the previous line
          # receives the :update message with whatever params are
          # submitted in the request.
          expect_any_instance_of(Channel).to receive(:update).with(ActionController::Parameters.new("name" => "MyString").permit(:name))
          patch :update, params: {:id => channel.to_param, :channel => { "name" => "MyString" }}
        end

        it "assigns the requested channel as @channel" do
          channel = user.channels.create! valid_attributes
          channel = Channel.find(channel.id)
          patch :update, params: {:id => channel.to_param, :channel => valid_attributes}
          expect(assigns(:channel)).to eq(channel)
        end

        it "redirects to the channel" do
          channel = user.channels.create! valid_attributes
          channel = Channel.find(channel.id)
          patch :update, params: {:id => channel.to_param, :channel => valid_attributes}
          expect(response).to redirect_to(channel)
        end
      end

      describe "with invalid params" do
        it "assigns the channel as @channel" do
          channel = user.channels.create! valid_attributes
          channel = Channel.find(channel.id)
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Channel).to receive(:save).and_return(false)
          patch :update, params: {:id => channel.to_param, :channel => { "name" => "invalid value" }}
          expect(assigns(:channel)).to eq(channel)
        end

        it "re-renders the 'edit' template" do
          channel = user.channels.create! valid_attributes
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Channel).to receive(:save).and_return(false)
          patch :update, params: {:id => channel.to_param, :channel => { "name" => "invalid value" }}
          expect(response).to render_template("edit")
        end
      end
    end   
    describe "DELETE destroy" do
      it "destroys the requested channel" do
        channel = user.channels.create! valid_attributes
        expect {
          delete :destroy, params: {:id => channel.to_param}
        }.to change(Channel, :count).by(-1)
      end

      it "redirects to the channels list" do
        channel = user.channels.create! valid_attributes
        delete :destroy, params: {:id => channel.to_param}
        expect(response).to redirect_to(user_url(user))
      end
    end   
    describe "GET list_subscribers" do
      it "assigns subscribed and unsubscribed subscribers" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch.id)
        subs = (0..2).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        subscribed_subs = [subs[0],subs[1]]
        unsubscribed_subs = [subs[2]]        
        get :list_subscribers, params: {id:ch}
        expect(assigns(:channel)).to eq(ch)
        expect(assigns(:subscribed_subscribers)).to match_array(subscribed_subs)
        expect(assigns(:unsubscribed_subscribers)).to match_array(unsubscribed_subs)
      end
      it "works when there are no subscribers yet for a channel" do
        ch = create(:channel, user:user)
        ch = Channel.find(ch.id)
        subs = (0..2).map{create(:subscriber,user:user)}
        subscribed_subs = []
        unsubscribed_subs = [subs[0],subs[1],subs[2]]        
        get :list_subscribers, params: {id:ch}
        expect(assigns(:channel)).to eq(ch)
        expect(assigns(:subscribed_subscribers)).to match_array(subscribed_subs)
        expect(assigns(:unsubscribed_subscribers)).to match_array(unsubscribed_subs)
      end
    end 
    describe "POST add_subscriber" do
      it "should increase subscribed subscribers array by one" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch.id)
        subs = (0..2).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        new_sub = subs[2]
        expect {
          post :add_subscriber, params: {channel_id:ch.id, id:new_sub.id}
        }.to change(ch.subscribers,:count).by(1)
      end
      it "should redirect to channel subscriber list" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch.id)
        subs = (0..2).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        new_sub = subs[2]
        post :add_subscriber, params: {channel_id:ch.id, id:new_sub.id}
        expect(response).to redirect_to(list_subscribers_channel_url(ch))
      end      
    end  
    describe "POST remove_subscriber" do
      it "should decrease subscribed subscribers array by one" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch.id)
        subs = (0..1).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        sub_to_remove = subs[1]
        expect {
          post :remove_subscriber, params: {channel_id:ch.id, id:sub_to_remove.id}
        }.to change(ch.subscribers,:count).by(-1)
      end
      it "should redirect to channel subscriber list" do
        ch = create(:channel,user:user)
        ch = Channel.find(ch.id)
        subs = (0..1).map{create(:subscriber,user:user)}
        (0..1).each{|i| ch.subscribers << subs[i]}
        sub_to_remove = subs[1]
        post :remove_subscriber, params: {channel_id:ch.id, id:sub_to_remove.id}
        expect(response).to redirect_to(list_subscribers_channel_url(ch))
      end      
    end              
  end


end
