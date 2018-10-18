describe Commit do
  let(:project_id) { 1 }
  subject { described_class.new(project_id, "abc123", "See merge request ns/some_project!80") }

  describe "#diff" do
    let(:diffs) { [::Gitlab::ObjectifiedHash.new(:diff => "+++ some change")] }
    let(:response) { ::Gitlab::PaginatedResponse.new(diffs) }
    it "should return the diff" do
      allow_any_instance_of(::Gitlab::Client).to receive(:commit_diff).and_return(response)
      expect(subject.diff).to eq(diffs)
    end
  end
end
