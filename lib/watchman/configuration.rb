module Watchman
  class Configuration
    @namespaces
    @projects
    @rules
    @alerts

    class << self
      attr_writer :namespaces, :projects, :rules, :alerts, :branches

      def configure
        yield self
      end

      def should_audit?(push_event)
        audit_namespace?(push_event.project_namespace) && 
          audit_project?(push_event.project_name) &&
          audit_branch?(push_event.branch)
      end

      def branches=(branches)
        @branches = branches || []
        @branches.map!(:downcase)
      end

      def rules=(rules)
        @rules = rules || []
      end

      def alerts=(alerts)
        @alerts = alerts || {}
      end

      def namespaces=(namespaces)
        @namespaces = {"whitelist" => [], "blacklist" => []}.merge(namespaces)
        @namespaces["whitelist"].map!(&:downcase)
        @namespaces["blacklist"].map!(&:downcase)
      end

      def projects=(projects)
        @projects = {"whitelist" => [], "blacklist" => []}.merge(projects)
        @projects["whitelist"].map!(&:downcase)
        @projects["blacklist"].map!(&:downcase)
      end

      def gitlab_issue_project
        alert_gitlab = @alerts.try("gitlab_issue")
        project = alert_gitlab.try("project")
        raise ArgumentError.new("`project' not set for alert_type: `gitlab_issue'") if alert_gitlab.present? && project.blank?
        project
      end

      def gitlab_issue_description
        alert_gitlab = @alerts.try("gitlab_issue")
        alert_gitlab.try("description") || "%{project_name} failed an audit"
      end

      def skip_commit?(commit_data)
        changed_files = (commit_data["added"] || []) + (commit_data["removed"] || []) + (commit_data["modified"] || []) 

        rules = @rules || []
        return false if changed_files.empty? || rules.empty?

        rules.any? do |rule|
          raise ArgumentError.new("Unknown rule type `#{rule["type"]}'") unless rule["type"] == "ignore_when_all"
          skip = changed_files.all? { |file| rule["files"].any? { |regex| Regexp.new(regex).match(file) } }
          Rails.logger.info "#{commit_data["id"]} skipped due to rule #{rule["name"]}" if skip
          skip
        end
      end

      def gitlab_issue_labels
        alert_gitlab = @alerts.try("gitlab_issue")
        alert_gitlab.try("labels") || []
      end

      def alert_via_gitlab?
        @alerts.try("gitlab_issue").present?
      end

      def alert_via_slack?
        @alerts.try("slack").present?
      end

      private

      def audit_branch?(branch)
        branches = @branches || []
        return true if branches.empty?
        branches.include?(branch.downcase)
      end

      def audit_namespace?(namespace)
        whitelist_blacklist(@namespaces["whitelist"], @namespaces["blacklist"], namespace.downcase)
      end

      def audit_project?(project)
        whitelist_blacklist(@projects["whitelist"], @projects["blacklist"], project.downcase)
      end
      
      def whitelist_blacklist(whitelist, blacklist, needle)
        if whitelist.empty?
          blacklist.exclude? needle
        else
          set = whitelist - blacklist
          set.include? needle
        end
      end
    end
  end
end
