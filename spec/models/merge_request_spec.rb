describe MergeRequest do
  let(:project_id) { 1 }
  let(:api_data) { ::Gitlab::ObjectifiedHash.new(:iid => 1, :merge_commit_sha => "abc123") }
  subject { described_class.from_api_data(project_id, api_data) }

  describe "is_approved?" do
    let(:not_approved) { ::Gitlab::ObjectifiedHash.new(:approvals_left => 1) }
    let(:cant_merge) { ::Gitlab::ObjectifiedHash.new(:approvals_left => 0, :merge_status => "unknown") }
    let(:approved) { ::Gitlab::ObjectifiedHash.new(:approvals_left => 0, :merge_status => "can_be_merged") }

    context "when not enough approvals, mr is not approved" do
      it "should not be approved" do
        allow_any_instance_of(::Gitlab::Client).to receive(:get).and_return(not_approved)
        expect(subject).to_not be_is_approved
      end
    end

    context "when can't be merged, mr is not approved" do
      it "should not be approved" do
        allow_any_instance_of(::Gitlab::Client).to receive(:get).and_return(cant_merge)
        expect(subject).to_not be_is_approved
      end
    end

    context "when has approvals and can be merged, mr is approved" do
      it "should not be approved" do
        allow_any_instance_of(::Gitlab::Client).to receive(:get).and_return(approved)
        expect(subject).to be_is_approved
      end
    end
  end

  describe "diff_identical?" do
    let(:commit_diffs) { [::Gitlab::ObjectifiedHash.new("diff" => "+++ Adding a line")] }
    let(:merge_request_diffs) { ::Gitlab::ObjectifiedHash.new("changes" => [{"diff" => "--- Removing a line"}]) }
    let(:commit) { Commit.new(1, "sha", "commit message") }
    context "when diff not the same" do
      it "should not be identical" do
        allow_any_instance_of(::Gitlab::Client).to receive(:merge_request_changes).and_return(merge_request_diffs)
        expect(subject.diff_identical?(commit_diffs)).to be false
      end
    end

    context "when diff same" do
      let(:merge_request_diffs) { ::Gitlab::ObjectifiedHash.new("changes" => [{"diff" => "+++ Adding a line"}]) }
      it "should be identical" do
        allow_any_instance_of(::Gitlab::Client).to receive(:merge_request_changes).and_return(merge_request_diffs)
        expect(subject.diff_identical?(commit_diffs)).to be true
      end
    end

    context "when diff same but differs by range markers" do
      let(:merge_request_diffs) { ::Gitlab::ObjectifiedHash.new("changes" => [{"diff" => "@@ -79,6 +79,7 @@\n+++ Adding a line"}]) }
      it "should be identical" do
        allow_any_instance_of(::Gitlab::Client).to receive(:merge_request_changes).and_return(merge_request_diffs)
        expect(subject.diff_identical?(commit_diffs)).to be true
      end
    end
  end
end
