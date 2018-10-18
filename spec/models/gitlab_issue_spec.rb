describe GitlabIssue do
  let(:params) {
    {
      :event_name => "push",
      :ref => "refs/head/master",
      :project => {
        :id => 1,
        :name => "Some_project"
      },
      :commits => [],
      :total_commits_count => 0
    }
  }
  let(:push_event) { PushEvent.new(params) }
  subject { described_class.new(push_event) }

  describe "#create!" do
    let(:project) { ::Gitlab::ObjectifiedHash.new(:id => 2, :name => "Some_project") }
    let(:url) { "https://gitlab.company.com/ns/some_project/issues/1" }
    let(:new_issue) { ::Gitlab::ObjectifiedHash.new(:web_url => url) }

    it "should create a Gitlab issue and return url" do
      allow_any_instance_of(::Gitlab::Client).to receive(:project).and_return(project)
      expect_any_instance_of(::Gitlab::Client).to receive(:create_issue).with(project.id, "Some_project failed an audit", :description => "\n\n", :labels => []).and_return(new_issue)
      expect(subject.create!).to be url
    end
  end
end
