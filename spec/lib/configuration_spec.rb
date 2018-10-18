describe Watchman::Configuration do
  describe "#should_audit?" do
    let(:push_event) { PushEvent.new({:project => {:name => "Project", :namespace => "Bar"}, :ref => "refs/heads/qa"}) }

    context "when nothing is whitelisted" do
      it "should only *not* audit projects/namespaces that are blacklisted" do
        Watchman::Configuration.namespaces = {"blacklist" => ["foo", "bar", "baz"]}
        Watchman::Configuration.projects = {}
        expect(Watchman::Configuration.should_audit?(push_event)).to be false

        Watchman::Configuration.namespaces = {"blacklist" => ["foo", "baz"]}
        Watchman::Configuration.projects = {}
        expect(Watchman::Configuration.should_audit?(push_event)).to be true
      end
    end

    context "when project/namespace whitelisted" do
      it "should only audit project/namespace if project is whitelisted" do
        Watchman::Configuration.namespaces = {"whitelist" => ["foo", "bar", "baz"]}
        Watchman::Configuration.projects = {}
        expect(Watchman::Configuration.should_audit?(push_event)).to be true

        Watchman::Configuration.namespaces = {"whitelist" => ["foo", "baz"]}
        Watchman::Configuration.projects = {}
        expect(Watchman::Configuration.should_audit?(push_event)).to be false

        Watchman::Configuration.namespaces = {"whitelist" => ["foo", "bar", "baz"], "blacklist" => ["bar"]}
        Watchman::Configuration.projects = {}
        expect(Watchman::Configuration.should_audit?(push_event)).to be false
      end
    end
  end

  describe "#skip_commit?" do
    it "should raise if rule type unknown" do
      Watchman::Configuration.rules = [{"type" => "unknown_rule_type", "files" => ["^ignore_dir/"]}]
      expect { Watchman::Configuration.skip_commit?({"modified" => ["some_file.rb"]}) }.to raise_error
    end

    it "should apply rules to files" do
      Watchman::Configuration.rules = [{"type" => "ignore_when_all", "files" => ["^ignore_dir/"]}]
      skipped = Watchman::Configuration.skip_commit?({"modified" => ["ignore_dir/some_file.rb", "dont_ignore_dir/other_file.rb"]})
      expect(skipped).to be false

      Watchman::Configuration.rules = [{"type" => "ignore_when_all", "files" => ["^ignore_dir/", "^other_dir/"]}]
      skipped = Watchman::Configuration.skip_commit?({"modified" => ["ignore_dir/some_file.rb", "other_dir/other_file.rb"]})
      expect(skipped).to be true
    end
  end
end
