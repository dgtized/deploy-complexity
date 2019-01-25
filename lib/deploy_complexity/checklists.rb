# frozen_string_literal: true

# define a bunch of checklist items that can be added to PRs automatically
module Checklists
  # all checklists should inherit from this class. It makes sure that the
  # checklist output is consistent in the PR so we don't get duplicates.
  class Checklist
    def id
      "checklist:#{self.class.name}"
    end

    def title
      "**#{human_name} Checklist**"
    end

    def to_s
      self.class.name
    end

    def for_pr_body
      "\n\n<!-- #{id} -->\n#{title}\n\n#{checklist}"
    end
  end

  # all these subclasses should be self-descriptive from their classnames, so go
  # away rubocop.
  # rubocop:disable Style/Documentation

  # Github-flavored Markdown doesn't wrap line breaks, so we need to disable
  # line length checks for now.
  # rubocop:disable Metrics/LineLength

  # Some checks are on quite a few files! They're simple checks, so the
  # cyclomatic complexity here is not actually too bad for a human.
  # rubocop:disable Metrics/CyclomaticComplexity

  class RubyFactoriesChecklist < Checklist
    def human_name
      "Ruby Factories"
    end

    def checklist
      '
- [ ] RSpec: use [traits](https://robots.thoughtbot.com/remove-duplication-with-factorygirls-traits) to make the default case fast
      '.strip
    end

    def relevant_for(files)
      files.select { |file| file.start_with?("spec/factories") }
    end
  end

  class ElmFactoriesChecklist < Checklist
    def human_name
      "Elm Factories"
    end

    def checklist
      '
- [ ] Elm fuzz tests: use [shortList](https://github.com/NoRedInk/NoRedInk/blob/72626abf20e44eb339dd60ebb716e9447910127f/ui/tests/SpecHelpers.elm#L59) when a list fuzzer is generating too many cases
      '.strip
    end

    def relevant_for(files)
      files.select { |file| file.start_with?("ui/tests/") }
    end
  end

  class CapistranoChecklist < Checklist
    def human_name
      "Capistrano"
    end

    def checklist
      "
The process for testing capistrano is to deploy the capistrano changes branch to staging prior to merging to master and verify the deploy doesn't explode.

- [ ] Make a branch with capistrano changes
- [ ] Wait for free time to test staging
- [ ] Reset/deploy that branch to staging using the normal jenkins deploy process
- [ ] Verify the deploy passes
  - If it doesn't, fix the branch and redeploy until it works
  - [ ] If it does, reset back to origin/master and request review of the PR
      ".strip
    end

    def relevant_for(files)
      files.select do |file|
        file == "Capfile" \
          || file == "Gemfile" \
          || file.start_with?("lib/capistrano/") \
          || file.start_with?("lib/deploy/") \
          || file.start_with?("config/deploy") \
          || !file.match('.*[\b_\./]cap[\b_\./].*').nil?
      end
    end
  end

  class OpsWorksChecklist < Checklist
    def human_name
      "OpsWorks"
    end

    def checklist
      "
- [ ] Change the source code branch for staging to the branch being tested in the opsworks UI
- [ ] Rebase your code over `origin/staging` to prevent a successful deploy of your changes from making staging run possibly outdated code
- [ ] Turn on an additional time-based instance in the layer ([see instructions](https://github.com/NoRedInk/wiki/blob/1f618042ed1d6b7c7297ec2672ae568e57944fde/ops-playbook/ops-plays.md#using-opsworks-to-bring-up-an-additional-time-based-instance))
- [ ] Verify that the instances passes setup to online and doesn't fail
      ".strip
    end

    def relevant_for(files)
      files.select do |file|
        file.start_with?("config/deploy") \
          || file.include?("opsworks") \
          || file.start_with?("deploy/") \
          || file.start_with?("lib/deploy/")
      end
    end
  end

  class RoutesChecklist < Checklist
    def human_name
      "Routes"
    end

    def checklist
      '
- [ ] Retired routes are redirected
      '.strip
    end

    def relevant_for(files)
      files.select { |file| file == "config/routes.rb" }
    end
  end

  class ResqueChecklist < Checklist
    def human_name
      "Resque"
    end

    def checklist
      '
- [ ] Resque jobs should not be allowed to change their `.perform` signature. Rather, create a new resque job and retire the old one post-deploy after the queue is empty
      '.strip
    end

    def relevant_for(files)
      files.select { |file| file.start_with? "app/jobs" }
    end
  end

  class MigrationChecklist < Checklist
    def human_name
      "Migrations"
    end

    def checklist
      '
- [ ] If there are any potential [Slow Migrations](https://github.com/NoRedInk/wiki/blob/master/Slow-Migrations.md), make sure that:
  - [ ] They are in separate PRs so each can be run independently
  - [ ] There is a deployment plan where the resulting code on prod will support the db schema both before and after the migration
- [ ] If migrations include dropping a column, modifying a column, or adding a non-nullable column, ensure the previously deployed model is prepared to handle both the previous schema and the new schema. ([See "Rails Migrations with Zero Downtime](https://blog.codeship.com/rails-migrations-zero-downtime/)")
      '.strip
    end

    def relevant_for(files)
      files.select { |file| file.start_with? "db/migrate/" }
    end
  end

  class DockerfileChecklist < Checklist
    def human_name
      "Dockerfile"
    end

    def checklist
      '
- [ ] If you added a dependency to the Dockerfile for a script that will be called during both CI builds **and** Deploy builds then you should also add that dependency to the chef recipe for [jenkins_common](https://github.com/NoRedInk/NoRedInk-chef/blob/master/site-cookbooks/noredink/recipes/jenkins_common.rb).
  - consequence of not doing this: deploys will break!
      '.strip
    end

    def relevant_for(files)
      files.select { |file| file.include? "Dockerfile" }
    end
  end

  class NixChecklist < Checklist
    def human_name
      "Nix"
    end

    def checklist
      '
- [Instructions on how to use Nix](https://github.com/NoRedInk/wiki/blob/master/engineering/using-nix.md)
- [ ] changes build successfully with Nix (`nix-shell --pure` to check)
- [ ] once approved, but before merging, make sure to update the Nix cache so that other people don\'t have to rebuild all changes. Run `script/cache_nix_shell.sh`.
      '
    end

    def relevant_for(files)
      files.select do |file|
        file.start_with?("nix") \
          || file.end_with?("nix") \
          || file == "Gemfile" \
          || file == "Gemfile.lock" \
          || file.end_with?("package.json") \
          || file.end_with?("package-lock.json") \
          || file == "requirements.txt"
      end
    end
  end

  # all done!
  # rubocop:enable Style/Documentation
  # rubocop:enable Metrics/LineLength
  # rubocop:enable Metrics/CyclomaticComplexity

  # Check for checklists, given a list of checkers
  class Checker
    def initialize(checklists)
      @checklists = checklists
    end

    def for_files(files)
      @checklists
        .map(&:new)
        .map { |checker| [checker, checker.relevant_for(files)] }
        .to_h
        .reject { |_, values| values.empty? }
    end
  end

  module_function

  CHECKLISTS = [
    RubyFactoriesChecklist,
    ElmFactoriesChecklist,
    CapistranoChecklist,
    OpsWorksChecklist,
    RoutesChecklist,
    ResqueChecklist,
    MigrationChecklist,
    DockerfileChecklist,
    NixChecklist
  ].freeze

  def for_files(files)
    Checker.new(CHECKLISTS).for_files(files)
  end
end
