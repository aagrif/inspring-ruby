require 'rails_helper'

describe  SubscriberActivitiesController do   
  it "does not recognize the new,create and destory actions" do
    expect {get :new, params: {}}.to raise_error(ActionController::UrlGenerationError)
    expect {post :create, params: {}}.to raise_error(ActionController::UrlGenerationError)
    expect {delete :destroy, params: {}}.to raise_error(ActionController::UrlGenerationError)
  end
  let(:user){create(:user)}
  let(:channel) {create(:channel,user:user)}
  let(:channel_group) {create(:channel_group,user:user)}
  let(:message) {create(:message,channel:channel)}
  let(:subscriber) {create(:subscriber,user:user)}
  let(:subscriber_response){create(:subscriber_response,message:message,subscriber:subscriber,channel:channel)}
  let(:other_subscriber_response){create(:subscriber_response,channel:channel)}
  let(:channel_group_response){create(:subscriber_response,channel_group:channel_group)}
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    channel.subscribers << subscriber
  end
  
  describe "guest user" do
    it "is redirected to signup form always and not allowed to alter db" do
      get :index, params: {subscriber_id:subscriber}
      expect(response).to redirect_to new_user_session_path

      get :show, params: {subscriber_id:subscriber,:id => subscriber_response.to_param}
      expect(response).to redirect_to new_user_session_path

      get :edit, params: {subscriber_id:subscriber,:id => subscriber_response.to_param}
      expect(response).to redirect_to new_user_session_path

      expect_any_instance_of(SubscriberResponse).to_not receive(:update)
      patch :update, params: {subscriber_id:subscriber,:id => subscriber_response.to_param, :caption => "Some Caption"}

    end
  end

  describe "one user" do
    it "is not be able to access other user's subscriber activities" do
      another_user = create(:user)
      sign_in another_user

      get :index, params: {subscriber_id:subscriber}
      expect(response).to redirect_to root_url

      get :show, params: {subscriber_id:subscriber,:id => subscriber_response.to_param}
      expect(response).to redirect_to root_url

      get :edit, params: {subscriber_id:subscriber,:id => subscriber_response.to_param}
      expect(response).to redirect_to root_url

      expect_any_instance_of(SubscriberActivity).to_not receive(:update)
      patch :update, params: {subscriber_id:subscriber,:id => subscriber_response.to_param, :caption => "Some Caption"}

    end
  end

  describe "valid user" do
    before do
      sign_in user
    end
    describe "GET index" do
      it "when called with subscriber id,  lists all his activities" do
        get :index, params: {subscriber_id:subscriber}
        expect(assigns(:subscriber_activities)).to eq([SubscriberActivity.find(subscriber_response.id)])
      end
      it "when called for a message, lists all its subscriber activities" do
        get :index, params: {message_id:message,channel_id:channel}
        expect(assigns(:subscriber_activities)).to eq([SubscriberActivity.find(subscriber_response.id)])
      end
      it "when called for a channel, lists all its subscriber activities" do
        get :index, params: {channel_id:channel}
        expect(assigns(:subscriber_activities)).to match_array([SubscriberActivity.find(subscriber_response.id),
                    SubscriberActivity.find(other_subscriber_response.id)])
      end
      it "when called for a channel_group, lists all its subscriber activities" do
        get :index, params: {channel_group_id:channel_group}
        expect(assigns(:subscriber_activities)).to match_array([SubscriberActivity.find(channel_group_response.id)])
      end

    end

    describe "GET show" do
      it "assigns the requested message's subscriber activity as @subscriber_activity" do
        get :show, params: {message_id:message,channel_id:channel,:id => subscriber_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(subscriber_response.id))
      end
      it "assigns the requested subscriber's subscriber activity as @subscriber_activity" do
        get :show, params: {subscriber_id:subscriber,:id => subscriber_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(subscriber_response.id))
      end   
      it "assigns the requested channel's subscriber activity as @subscriber_activity" do
        get :show, params: {channel_id:channel,:id => subscriber_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(subscriber_response.id))
      end   
      it "assigns the requested channel_group's subscriber activity as @subscriber_activity" do
        get :show, params: {channel_group_id:channel_group,:id => channel_group_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(channel_group_response.id))
      end                  
    end

    describe "GET edit" do
      it "assigns the requested message's subscriber activity as @subscriber_activity" do
        get :edit, params: {message_id:message,channel_id:channel,:id => subscriber_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(subscriber_response.id))
      end
      it "assigns the requested subscriber's subscriber activity as @subscriber_activity" do
        get :edit, params: {subscriber_id:subscriber,:id => subscriber_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(subscriber_response.id))
      end   
      it "assigns the requested channel's subscriber activity as @subscriber_activity" do
        get :edit, params: {channel_id:channel,:id => subscriber_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(subscriber_response.id))
      end   
      it "assigns the requested channel_group's subscriber activity as @subscriber_activity" do
        get :edit, params: {channel_group_id:channel_group,:id => channel_group_response.to_param}
        expect(assigns(:subscriber_activity)).to eq(SubscriberActivity.find(channel_group_response.id))
      end      
    end

    describe "PATCH update" do
      describe "with valid params" do
        it "updates the requested message's subscriber activity" do
          expect_any_instance_of(SubscriberResponse).to receive(:update).with(ActionController::Parameters.new("caption" => "Sample Caption").permit(:caption))
          patch :update, params: {message_id:message,channel_id:channel,:id => subscriber_response.to_param, :subscriber_activity=>{"caption" => "Sample Caption"} }
        end
        it "updates the requested subscriber's subscriber activity" do
          expect_any_instance_of(SubscriberResponse).to receive(:update).with(ActionController::Parameters.new("caption" => "Sample Caption").permit(:caption))
          patch :update, params: {subscriber_id:subscriber,:id => subscriber_response.to_param, :subscriber_activity=>{"caption" => "Sample Caption"} }
        end
        it "updates the requested channel's subscriber activity" do 
          expect_any_instance_of(SubscriberResponse).to receive(:update).with(ActionController::Parameters.new("caption" => "Sample Caption").permit(:caption))
          patch :update, params: {channel_id:channel,:id => subscriber_response.to_param, :subscriber_activity=>{"caption" => "Sample Caption"} }
        end
        it "updates the requested channel group's subscriber activity" do
          expect_any_instance_of(SubscriberResponse).to receive(:update).with(ActionController::Parameters.new("caption" => "Sample Caption").permit(:caption))
          patch :update, params: {channel_group_id:channel_group,:id => channel_group_response.to_param, :subscriber_activity=>{"caption" => "Sample Caption"} }
        end                        

        it "redirects to the subscriber activity" do
          patch :update, params: {message_id:message,channel_id:channel,:id => subscriber_response.to_param, :subscriber_activity=>{"caption" => "Sample Caption"}}
          expect(response).to redirect_to :action => :show, message_id:message,channel_id:channel,id:subscriber_response.to_param
        end
      end

      describe "with invalid params" do
        it "re-renders the 'edit' template" do
          allow_any_instance_of(SubscriberResponse).to receive(:save).and_return(false)
          patch :update, params: {message_id:message,channel_id:channel,:id => subscriber_response.to_param, :subscriber_activity=>{"caption" => "Sample Caption"}}
          expect(response).to render_template("edit")
        end
     end
    end
  end
end
