require "rails_helper"

RSpec.describe ModelNamesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/model_names").to route_to("model_names#index")
    end

    it "routes to #new" do
      expect(get: "/model_names/new").to route_to("model_names#new")
    end

    it "routes to #show" do
      expect(get: "/model_names/1").to route_to("model_names#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/model_names/1/edit").to route_to("model_names#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/model_names").to route_to("model_names#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/model_names/1").to route_to("model_names#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/model_names/1").to route_to("model_names#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/model_names/1").to route_to("model_names#destroy", id: "1")
    end
  end
end
