class MergeRequest
  RANGE_MARKER_REGEX = /^@@[^@]+@@/
  STATUS_CAN_BE_MERGED = "can_be_merged".freeze

  private_class_method :new
  attr_reader :project_id, :id, :merge_commit_sha

  def initialize(project_id, merge_request_data)
    @project_id = project_id
    @id = merge_request_data.iid
    @merge_commit_sha = merge_request_data.merge_commit_sha
  end

  def is_approved?
    approvals.approvals_left == 0 && approvals.merge_status == STATUS_CAN_BE_MERGED
  end

  def diff_identical?(commit_diffs)
    strip_range_identifiers = lambda { |file| file["diff"] = file["diff"].split("\n").reject { |line| line =~ RANGE_MARKER_REGEX }.join("\n") }
    sort_by_path = lambda { |diff1, diff2| diff1["new_path"] <=> diff2["new_path"] }

    left = commit_diffs.collect(&:to_h).each(&strip_range_identifiers).sort(&sort_by_path)
    right = diff.each(&strip_range_identifiers).sort(&sort_by_path)

    HashDiff.diff(left, right).empty?
  end

  def self.from_api_data(project_id, merge_request_data)
    new(project_id, merge_request_data)
  end

  private

  def diff
    @diff ||= ::Gitlab.client.merge_request_changes(project_id, id).changes
  end

  def approvals
    @approvals ||= ::Gitlab.client.get("/projects/#{project_id}/merge_requests/#{id}/approvals")
  end
end
