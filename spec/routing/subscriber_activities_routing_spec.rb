require 'rails_helper'

describe SubscriberActivitiesController do
  describe "routing" do

    it "routes to #index" do
      expect(get("subscriber_activities")).to route_to controller:"subscriber_activities",
        action:"index"
    end

    it "routes to #show" do
      expect(get("subscriber_activities/1")).to route_to controller:"subscriber_activities",
        :id => "1", action:"show"
    end

    it "routes to #edit" do
      expect(get("subscriber_activities/1/edit")).to route_to controller:"subscriber_activities",
        :id => "1", action:"edit"
    end

    it "routes to #update" do
      expect(patch("subscriber_activities/1")).to route_to controller:"subscriber_activities",
        :id => "1", action:"update"
    end

  end
end
