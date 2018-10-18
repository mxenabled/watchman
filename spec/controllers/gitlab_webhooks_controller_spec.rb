require "rails_helper"

RSpec.describe GitlabWebhooksController do
  describe "#push_event" do
    let(:params) {
      {
        :event_name => "push",
        :ref => "refs/head/production",
        :project => {
          :id => 1
        }
      }
    }

    it "should create gitlab issue when push event fails audit" do
      allow_any_instance_of(PushEvent).to receive(:passed_audit?).and_return(false)
      expect_any_instance_of(GitlabIssue).to receive(:create!)
      post :route, params: params
      expect(response.status).to eq(200)
    end

    it "shouldn't do anything if push event passes audit" do
      allow_any_instance_of(PushEvent).to receive(:passed_audit?).and_return(true)
      expect_any_instance_of(GitlabIssue).to_not receive(:create!)
      post :route, params: params
      expect(response.status).to eq(200)
    end
  end
end
