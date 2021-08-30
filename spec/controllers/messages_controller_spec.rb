require 'rails_helper'
describe MessagesController do
  let(:user){create(:user)}
  let(:channel) {create(:channel,user:user)}
  let(:valid_attributes) { attributes_for(:message) }
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "guest user" do
    it "is redirected to signup form always and not allowed to alter db" do
      message = channel.messages.create! valid_attributes

      get :index, params: {channel_id:channel}
      expect(response).to redirect_to new_user_session_path

      get :select_import, params: {channel_id:channel}
      expect(response).to redirect_to new_user_session_path

      get :import, params: {channel_id:channel}
      expect(response).to redirect_to new_user_session_path

      get :show, params: {channel_id:channel,:id => message.to_param}
      expect(response).to redirect_to new_user_session_path

      get :responses, params: {channel_id:channel,:id => message.to_param}
      expect(response).to redirect_to new_user_session_path

      get :new, params: {channel_id:channel}
      expect(response).to redirect_to new_user_session_path

      get :edit, params: {channel_id:channel,:id => message.to_param}
      expect(response).to redirect_to new_user_session_path

      expect {
            post :create, params: {channel_id:channel,:message => valid_attributes}
          }.to_not change(Message, :count)

      expect_any_instance_of(Message).to_not receive(:update)
      patch :update, params: {channel_id:channel,:id => message.to_param, :message => { "title" => "MyText" }}

      expect {
          delete :destroy, params: {channel_id:channel,:id => message.to_param}
        }.to_not change(Message, :count)
    end
  end

  describe "one user" do
    it "is not be able to access other user's messages" do
      message = channel.messages.create! valid_attributes
      another_user = create(:user)
      sign_in another_user

      get :select_import, params: {channel_id:channel}
      expect(response).to redirect_to root_url

      post :import, params: {channel_id:channel}
      expect(response).to redirect_to root_url

      get :index, params: {channel_id:channel}
      expect(response).to redirect_to root_url

      get :show, params: {channel_id:channel,:id => message.to_param}
      expect(response).to redirect_to root_url

      get :responses, params: {channel_id:channel,:id => message.to_param}
      expect(response).to redirect_to root_url

      get :new, params: {channel_id:channel}
      expect(response).to redirect_to root_url

      get :edit, params: {channel_id:channel,:id => message.to_param}
      expect(response).to redirect_to root_url

      expect {
            post :create, params: {channel_id:channel,:message => valid_attributes}
          }.to_not change(Message, :count)

      expect_any_instance_of(Message).to_not receive(:update)
      patch :update, params: {channel_id:channel,:id => message.to_param, :message => { "title" => "MyText" }}

      expect {
          delete :destroy, params: {channel_id:channel,:id => message.to_param}
        }.to_not change(Message, :count)

    end
  end

  describe "valid user" do
    before do
      sign_in user
    end
    describe "GET index" do
      it "assigns all messages as @messages" do
        message = channel.messages.create! valid_attributes
        get :index, params: {user_id:user,channel_id:channel}
        expect(assigns(:messages)).to eq([Message.find(message.id)])
      end
    end

    describe "GET show" do
      it "assigns the requested message as @message" do
        message = channel.messages.create! valid_attributes
        get :show, params: {channel_id:channel,:id => message.to_param}
        expect(assigns(:message)).to eq(Message.find(message.id))
      end
    end

    describe "GET responses" do
      subject { assigns(:message) }
      it "assigns the requested message as @message" do
        message = channel.messages.create! valid_attributes
        get :show, params: {channel_id:channel,:id => message.to_param}
        expect(subject).to eq(Message.find(message.id))
      end
    end

    describe "GET new" do
      it "assigns a new message as @message" do
        get :new, params: {channel_id:channel}
        expect(assigns(:message)).to be_a_new(Message)
      end
    end

    describe "GET edit" do
      it "assigns the requested message as @message" do
        message = channel.messages.create! valid_attributes
        get :edit, params: {channel_id:channel,:id => message.to_param}
        expect(assigns(:message)).to eq(Message.find(message.id))
      end
    end

    describe "POST create" do
      describe "with valid params" do
        it "creates a new Message" do
          expect {
            post :create, params: {channel_id:channel,:message => valid_attributes}
          }.to change(Message, :count).by(1)
        end

        it "assigns a newly created message as @message" do
          post :create, params: {channel_id:channel,:message => valid_attributes}
          expect(assigns(:message)).to be_a(Message)
          expect(assigns(:message)).to be_persisted
        end

        it "redirects to the created message" do
          post :create, params: {channel_id:channel,:message => valid_attributes}
          expect(response).to redirect_to([channel,Message.last])
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved message as @message" do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Message).to receive(:save).and_return(false)
          post :create, params: {channel_id:channel,:message => { "title" => "invalid value" }}
          expect(assigns(:message)).to be_a_new(Message)
        end

        it "re-renders the 'new' template" do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Message).to receive(:save).and_return(false)
          post :create, params: {channel_id:channel,:message => { "title" => "invalid value" }}
          expect(response).to render_template("new")
        end
      end
    end

    describe "PATCH update" do
      describe "with valid params" do
        it "updates the requested message" do
          message = channel.messages.create! valid_attributes
          # Assuming there are no other messages in the database, this
          # specifies that the Message created on the previous line
          # receives the :update message with whatever params are
          # submitted in the request.
          expect_any_instance_of(Message).to receive(:save)
          patch :update, params: {channel_id:channel,:id => message.to_param, :message => { "title" => "MyText" }}
        end

        it "assigns the requested message as @message" do
          message = channel.messages.create! valid_attributes
          patch :update, params: {channel_id:channel,:id => message.to_param, :message => valid_attributes}
          expect(assigns(:message)).to eq(Message.find(message.id))
        end

        it "redirects to the message" do
          message = channel.messages.create! valid_attributes
          patch :update, params: {channel_id:channel,:id => message.to_param, :message => valid_attributes}
          expect(response).to redirect_to([channel,message])
        end
      end

      describe "with invalid params" do
        it "assigns the message as @message" do
          message = channel.messages.create! valid_attributes
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Message).to receive(:save).and_return(false)
          patch :update, params: {channel_id:channel,:id => message.to_param, :message => { "title" => "invalid value" }}
          expect(assigns(:message)).to eq(Message.find(message.id))
        end

        it "re-renders the 'edit' template" do
          message = channel.messages.create! valid_attributes
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Message).to receive(:save).and_return(false)
          patch :update, params: {channel_id:channel,:id => message.to_param, :message => { "title" => "invalid value" }}
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE destroy" do
      it "destroys the requested message" do
        message = channel.messages.create! valid_attributes
        expect {
          delete :destroy, params: {channel_id:channel,id: message.to_param}
        }.to change(Message, :count).by(-1)
      end

      it "redirects to the channel show" do
        message = channel.messages.create! valid_attributes
        delete :destroy, params: {channel_id:channel,id: message.to_param}
        expect(response).to redirect_to(channel_url(channel))
      end
    end

    describe "POST broadcast" do
      it "calls broadcast for message for all subscribers" do
        message = create(:message,channel:channel)
        subscribers = (0..2).map {create(:subscriber,user:user)}
        subscribers.each do |subs|
          channel.subscribers << subs
        end
        sub_nos = subscribers.map {|s| s.phone_number}
        expect_any_instance_of(Message).to receive(:broadcast) do |phone_nos|
          phone_nos =~ sub_nos
        end
        post :broadcast, params: {channel_id:channel, id:message.to_param}
      end
    end

    describe "GET select_import" do
      it "assigns @channel with the channel" do
        get :select_import, params: {user_id:user,channel_id:channel}
        expect(assigns(:channel)).to eq(Channel.find(channel.id))
      end
    end



  end


end
