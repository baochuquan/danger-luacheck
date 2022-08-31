require "pathname"
ROOT = Pathname.new(File.expand_path("..", __dir__))
$:.unshift((ROOT + "lib").to_s)
$:.unshift((ROOT + "spec").to_s)

require "bundler/setup"
require "pry"

require "rspec"
require "danger"

if `git remote -v` == ""
  puts "You cannot run tests without setting a local git remote on this repo"
  puts "It's a weird side-effect of Danger's internals."
  exit(0)
end

# Use coloured output, it's the best.
RSpec.configure do |config|
  config.filter_gems_from_backtrace "bundler"
  config.color = true
  config.tty = true
end

require "danger_plugin"

# These functions are a subset of https://github.com/danger/danger/blob/master/spec/spec_helper.rb
# If you are expanding these files, see if it's already been done ^.

# A silent version of the user interface,
# it comes with an extra function `.string` which will
# strip all ANSI colours from the string.

# rubocop:disable Lint/NestedMethodDefinition
def testing_ui
  @output = StringIO.new
  def @output.winsize
    [20, 9999]
  end

  cork = Cork::Board.new(out: @output)
  def cork.string
    out.string.gsub(/\e\[([;\d]+)?m/, "")
  end
  cork
end
# rubocop:enable Lint/NestedMethodDefinition

def testing_env
  {
    "BITRISE_PULL_REQUEST" => "4",
    "BITRISE_IO" => "true",
    "GIT_REPOSITORY_URL" => "git@github.com:artsy/eigen",
    "DANGER_GITHUB_API_TOKEN" => "123sbdq54erfsd3422gdfio"
  }
end

def testing_env_for_gitlab
  {
    "BITRISE_PULL_REQUEST" => "4",
    "BITRISE_IO" => "true",
    "GIT_REPOSITORY_URL" => "git@gitlab.com:artsy/eigen",
    "DANGER_GITLAB_API_TOKEN" => "123sbdq54erfsd3422gdfio"
  }
end

# A stubbed out Dangerfile for use in tests
def testing_dangerfile
  env = Danger::EnvironmentManager.new(testing_env)
  Danger::Dangerfile.new(env, testing_ui)
end

def testing_dangerfile_for_gitlab
  env = Danger::EnvironmentManager.new(testing_env_for_gitlab)
  Danger::Dangerfile.new(env, testing_ui)
end

def dummy_luacheck_result_1
  File.read(File.expand_path("fixtures/luacheck_result_1.xml", __dir__)).chomp
end
