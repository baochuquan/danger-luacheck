# frozen_string_literal: true

require File.expand_path("spec_helper", __dir__)

module Danger
  describe Danger::DangerLuacheck do
    let(:dangerfile) { testing_dangerfile }
    let(:plugin) { dangerfile.luacheck }

    it "should be a plugin" do
      expect(Danger::DangerLuacheck.new(nil)).to be_a Danger::Plugin
    end

    describe "#lint" do
      before do
        allow_any_instance_of(Danger::DangerfileGitPlugin).to receive(:added_files).and_return(["AMClick/src/AMClickResManager.lua"])
        allow_any_instance_of(Danger::DangerfileGitPlugin).to receive(:modified_files).and_return([])
      end

      context "luacheck issues were found" do
        before do
          allow_any_instance_of(Kernel).to receive(:system).with("which luacheck > /dev/null 2>&1").and_return(true)
          allow_any_instance_of(Kernel).to receive(:`).with("luacheck AMClick/src/AMClickResManager.lua --formatter JUnit").and_return(dummy_luacheck_result_1)
          allow_any_instance_of(Danger::DangerfileGitHubPlugin).to receive(:html_link).with("AMClick/src/AMClickResManager.lua#L20").and_return("<a href='https://github.com/baochuquan/android/blob/561827e46167077b5e53515b4b7349b8ae04610b/AMClickResManager.lua'>AMClickResManager.lua</a>")
          allow_any_instance_of(Danger::DangerfileGitHubPlugin).to receive(:html_link).with("AMClick/src/AMClickResManager.lua#L75").and_return("<a href='https://github.com/baochuquan/android/blob/561827e46167077b5e53515b4b7349b8ae04610b/AMClickResManager.lua'>AMClickResManager.lua</a>")
        end

        it "send markdown comment" do
          plugin.lint
          expect(dangerfile.status_report[:errors].size).to eq(2)
        end
      end

      context "luacheck issues were found with inline_mode: true" do
        before do
          allow_any_instance_of(Kernel).to receive(:system).with("which luacheck > /dev/null 2>&1").and_return(true)
          allow_any_instance_of(Kernel).to receive(:`).with("luacheck AMClick/src/AMClickResManager.lua --formatter JUnit").and_return(dummy_luacheck_result_1)
        end

        it "Sends inline comment" do
          plugin.lint(inline_mode: true)
          expect(dangerfile.status_report[:errors].size).to eq(2)
        end
      end
    end

    describe "#send_markdown_comment" do
      let(:limit) { 1 }

      before do
        allow_any_instance_of(Danger::DangerfileGitPlugin).to receive(:added_files).and_return(["AMClick/src/AMClickResManager.lua"])
        allow_any_instance_of(Danger::DangerfileGitPlugin).to receive(:modified_files).and_return([])

        allow_any_instance_of(Kernel).to receive(:system).with("which luacheck > /dev/null 2>&1").and_return(true)
        allow_any_instance_of(Kernel).to receive(:`).with("luacheck AMClick/src/AMClickResManager.lua --formatter JUnit").and_return(dummy_luacheck_result_1)
        plugin.limit = limit
      end

      context "limit is set" do
        it "equals number of luacheck results to limit" do
          plugin.lint(inline_mode: true)
          expect(dangerfile.status_report[:errors].size).to eq(limit)
        end
      end
    end
    #
    # You should test your custom attributes and methods here
    #
    # describe "with Dangerfile" do
    #   before do
    #     @dangerfile = testing_dangerfile
    #     @my_plugin = @dangerfile.luacheck

    #     # mock the PR data
    #     # you can then use this, eg. github.pr_author, later in the spec
    #     json = File.read("#{File.dirname(__FILE__)}/support/fixtures/github_pr.json") # example json: `curl https://api.github.com/repos/danger/danger-plugin-template/pulls/18 > github_pr.json`
    #     allow(@my_plugin.github).to receive(:pr_json).and_return(json)
    #   end

    #   # Some examples for writing tests
    #   # You should replace these with your own.

    #   it "Warns on a monday" do
    #     monday_date = Date.parse("2016-07-11")
    #     allow(Date).to receive(:today).and_return monday_date

    #     @my_plugin.warn_on_mondays

    #     expect(@dangerfile.status_report[:warnings]).to eq(["Trying to merge code on a Monday"])
    #   end

    #   it "Does nothing on a tuesday" do
    #     monday_date = Date.parse("2016-07-12")
    #     allow(Date).to receive(:today).and_return monday_date

    #     @my_plugin.warn_on_mondays

    #     expect(@dangerfile.status_report[:warnings]).to eq([])
    #   end
    # end
  end
end
