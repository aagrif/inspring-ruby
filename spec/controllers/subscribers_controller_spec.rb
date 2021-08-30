require 'rails_helper'

describe SubscribersController do
  let(:user){create(:user)}
  let(:valid_attributes) { { "name" => "MyString", "phone_number" => "+14082343434" } }
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "guest user" do
    it "is redirected to signup form always and not allowed to alter db" do 
      subscriber = user.subscribers.create! valid_attributes

      get :index, params: {}
      expect(response).to redirect_to new_user_session_path

      get :show, params: {:id => subscriber.to_param}
      expect(response).to redirect_to new_user_session_path

      get :new, params: {}
      expect(response).to redirect_to new_user_session_path

      get :edit, params: {:id => subscriber.to_param}
      expect(response).to redirect_to new_user_session_path

      expect {
            post :create, params: {:subscriber => valid_attributes}
          }.to_not change(Subscriber, :count)
      
      expect_any_instance_of(Subscriber).to_not receive(:update)
          patch :update, params: {:id => subscriber.to_param, :subscriber => { "name" => "MyString" }}

      expect {
          delete :destroy, params: {:id => subscriber.to_param}
        }.to_not change(Subscriber, :count)
    end
  end

  describe "one user" do
    it "is not be able to access other user's subscribers" do
      subscriber = user.subscribers.create! valid_attributes
      another_user = create(:user)
      sign_in another_user

      get :show, params: {:id => subscriber.to_param}
      expect(response).to redirect_to root_url

      get :edit, params: {:id => subscriber.to_param}
      expect(response).to redirect_to root_url
      
      expect_any_instance_of(Subscriber).to_not receive(:update)
          patch :update, params: {:id => subscriber.to_param, :subscriber => { "name" => "MyString" }}

      expect {
          delete :destroy, params: {:id => subscriber.to_param}
        }.to_not change(Subscriber, :count)
    end
  end  

  describe "valid user" do
    before do
      sign_in user
    end  

    describe "GET index" do
      it "assigns all subscribers as @subscribers" do
        subscriber = user.subscribers.create! valid_attributes
        get :index, params: {}
        expect(assigns(:subscribers)).to eq([subscriber])
      end
    end

    describe "GET show" do
      it "assigns the requested subscriber as @subscriber" do
        subscriber = user.subscribers.create! valid_attributes
        get :show, params: {:id => subscriber.to_param}
        expect(assigns(:subscriber)).to eq(subscriber)
      end
    end

    describe "GET new" do
      it "assigns a new subscriber as @subscriber" do
        get :new, params: {}
        expect(assigns(:subscriber)).to be_a_new(Subscriber)
      end
    end

    describe "GET edit" do
      it "assigns the requested subscriber as @subscriber" do
        subscriber = user.subscribers.create! valid_attributes
        get :edit, params: {:id => subscriber.to_param}
        expect(assigns(:subscriber)).to eq(subscriber)
      end
    end

    describe "POST create" do
      describe "with valid params" do
        it "creates a new Subscriber" do
          expect {
            post :create, params: {:subscriber => valid_attributes}
          }.to change(Subscriber, :count).by(1)
        end

        it "assigns a newly created subscriber as @subscriber" do
          post :create, params: {:subscriber => valid_attributes}
          expect(assigns(:subscriber)).to be_a(Subscriber)
          expect(assigns(:subscriber)).to be_persisted
        end

        it "redirects to the created subscriber" do
          post :create, params: {:subscriber => valid_attributes}
          expect(response).to redirect_to(Subscriber.last)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved subscriber as @subscriber" do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Subscriber).to receive(:save).and_return(false)
          post :create, params: {:subscriber => { "name" => "invalid value" }}
          expect(assigns(:subscriber)).to be_a_new(Subscriber)
        end

        it "re-renders the 'new' template" do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Subscriber).to receive(:save).and_return(false)
          post :create, params: {:subscriber => { "name" => "invalid value" }}
          expect(response).to render_template("new")
        end
      end
    end

    describe "PATCH update" do
      describe "with valid params" do
        it "updates the requested subscriber" do
          subscriber = user.subscribers.create! valid_attributes
          # Assuming there are no other subscribers in the database, this
          # specifies that the Subscriber created on the previous line
          # receives the :update message with whatever params are
          # submitted in the request.
          expect_any_instance_of(Subscriber).to receive(:update).with(ActionController::Parameters.new("name" => "MyString").permit(:name))
          patch :update, params: {:id => subscriber.to_param, :subscriber => { "name" => "MyString" }}
        end

        it "assigns the requested subscriber as @subscriber" do
          subscriber = user.subscribers.create! valid_attributes
          patch :update, params: {:id => subscriber.to_param, :subscriber => valid_attributes}
          expect(assigns(:subscriber)).to eq(subscriber)
        end

        it "redirects to the subscriber" do
          subscriber = user.subscribers.create! valid_attributes
          patch :update, params: {:id => subscriber.to_param, :subscriber => valid_attributes}
          expect(response).to redirect_to(subscriber)
        end
      end

      describe "with invalid params" do
        it "assigns the subscriber as @subscriber" do
          subscriber = user.subscribers.create! valid_attributes
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Subscriber).to receive(:save).and_return(false)
          patch :update, params: {:id => subscriber.to_param, :subscriber => { "name" => "invalid value" }}
          expect(assigns(:subscriber)).to eq(subscriber)
        end

        it "re-renders the 'edit' template" do
          subscriber = user.subscribers.create! valid_attributes
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Subscriber).to receive(:save).and_return(false)
          patch :update, params: {:id => subscriber.to_param, :subscriber => { "name" => "invalid value" }}
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE destroy" do
      it "destroys the requested subscriber" do
        subscriber = user.subscribers.create! valid_attributes
        expect {
          delete :destroy, params: {:id => subscriber.to_param}
        }.to change(Subscriber, :count).by(-1)
      end

      it "redirects to channel show" do
        subscriber = user.subscribers.create! valid_attributes
        delete :destroy, params: {:id => subscriber.to_param}
        expect(response).to redirect_to(subscribers_url)
      end
    end
  end
end
