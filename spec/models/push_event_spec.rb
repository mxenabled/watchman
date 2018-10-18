describe PushEvent do
  describe "passed_audit?" do
    before {
      Watchman::Configuration.namespaces = {}
      Watchman::Configuration.projects = {}
    }
    context "when branch is not audited" do
      let(:params) {
        {
          :event_name => "push",
          :ref => "refs/head/master",
          :project => {
            :id => 1,
            :namespace => "engineering",
            :name => "Project"
          },
          :commits => [],
          :total_commits_count => 0
        }
      }
      subject { described_class.new(params) }
      it "should pass audit" do
        expect(subject).to be_passed_audit
      end
    end

    context "when branch is audited" do
      let(:params) {
        {
          :event_name => "push",
          :ref => "refs/head/production",
          :project => {
            :id => 1,
            :namespace => "engineering",
            :name => "Project"
          },
          :commits => [commit],
          :total_commits_count => 1
        }
      }
      subject { described_class.new(params) }

      context "and when commit belongs to recent MR" do
        let(:commit) { { "id" => "MERGE_COMMIT_SHA", "modified" => ["some/file.rb"] } }
        let(:merge_request) { ::Gitlab::ObjectifiedHash.new(:iid => 1, :merge_commit_sha => "MERGE_COMMIT_SHA") }
        it "should pass audit" do
          allow_any_instance_of(::Gitlab::Client).to receive(:merge_requests).and_return([merge_request])
          allow_any_instance_of(::Gitlab::Client).to receive(:merge_request_commits).and_return([])
          allow_any_instance_of(MergeRequest).to receive(:is_approved?).and_return(true)
          expect(subject).to be_passed_audit
        end
      end

      context "and when commit doesn't belong nor is identical to recent MR" do
        let(:commit) { { "id" => "COMMIT_SHA", "modified" => ["some/file.rb"], "message" => "Change some/file.rb" } }
        let(:merge_request) { ::Gitlab::ObjectifiedHash.new(:iid => 1, :merge_commit_sha => "MERGE_COMMIT_SHA") }
        it "should fail audit" do
          allow_any_instance_of(::Gitlab::Client).to receive(:merge_requests).and_return([merge_request])
          allow_any_instance_of(::Gitlab::Client).to receive(:merge_request_commits).and_return([])
          allow_any_instance_of(MergeRequest).to receive(:is_approved?).and_return(true)
          allow_any_instance_of(MergeRequest).to receive(:diff).and_return([{"diff" => "+++ Adding a line"}])
          allow_any_instance_of(Commit).to receive(:diff).and_return([{"diff" => "--- Removing a line"}])

          expect(subject).to_not be_passed_audit
        end
      end

      context "and when commit's parent commit is identical to approved MR" do
        let(:commit) { { "id" => "COMMIT_SHA", "modified" => ["some/file.rb"], "message" => "" } }
        let(:merge_request) { ::Gitlab::ObjectifiedHash.new(:iid => 1, :merge_commit_sha => "MERGE_COMMIT_SHA") }

        it "should pass audit" do
          allow_any_instance_of(::Gitlab::Client).to receive(:merge_requests).and_return([merge_request])
          allow_any_instance_of(::Gitlab::Client).to receive(:merge_request_commits).and_return([])
          allow_any_instance_of(Commit).to receive(:diff)
          allow_any_instance_of(MergeRequest).to receive(:diff_identical?).and_return(true)
          allow_any_instance_of(MergeRequest).to receive(:is_approved?).and_return(true)

          expect(subject).to be_passed_audit
        end
      end

      context "and when too many commits pushed" do
        let(:params) {
          {
            :event_name => "push",
            :ref => "refs/head/stable",
            :project => {
              :id => 1,
              :namespace => "engineering",
              :name => "Project"
            },
            :commits => [],
            :total_commits_count => 21
          }
        }
        it "should fail audit" do
          expect(subject).to_not be_passed_audit
        end
      end
    end
  end
end
