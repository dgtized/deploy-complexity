#!/bin/usr/env ruby

require 'time'

def parse_when(tag)
  tag.match(/-(\d{4}-\d{2}-\d{2}-\d{2}\d{2})/) do |m|
    Time.strptime(m[1], '%Y-%m-%d-%H%M')
  end
end

REPO_URL = "https://github.com/NoRedInk/NoRedInk/"
PR_FORMAT = REPO_URL + "pull/%d - %s"
COMPARE_FORMAT= REPO_URL + "compare/%s...%s"
MIGRATE_FORMAT = REPO_URL + "blob/%s/db/migrate/%s"

def time_between_deploys(from, to)
  deploy_time = parse_when(to)
  last_time = parse_when(from)

  hours = if deploy_time
    (deploy_time - last_time) / 60**2
  end

  if hours.nil?
    "pending deploy"
  elsif hours < 24
    "after %2.1f %s" % [hours, "hours"]
  else
    "after %2.1f %s" % [(hours/24), "days"]
  end
end

def base_tag(from)
  base = case from
  when /staging/
    "staging"
  when /demo/
    "demo"
  else
    "production"
  end

  `git describe --match="#{base}*" #{to}~1`.chomp
end

def safe_name(name)
  name.chomp.split(%r{/}).last
end

def deploy(from, to)
  from = safe_name(from)
  to = safe_name(to)

  revision = `git rev-parse --short #{to}`.chomp

  time_delta = time_between_deploys(from, to)

  commits = `git log --oneline #{from}...#{to}`.split(/\n/)
  merges = commits.grep(/Merge/)

  shortstat = `git diff --shortstat --summary #{from}...#{to}`.split(/\n/)
  migrations = shortstat.grep(/migrate/).map do |line|
    line.match(%r{db/migrate/(.*)$}) do |m|
      MIGRATE_FORMAT % [to, m[1]]
    end
  end

  prs = merges.map { |line|
    line.match(/pull request #(\d+) from (.*)$/) do |m|
      [m[1].to_i, safe_name(m[2])]
    end
  }.compact

  puts "Deploy tag %s [%s]" % [to, revision]
  if commits.size > 0
    puts "%d prs of %d merges, %d commits %s" %
         [prs.count, merges.count, commits.count, time_delta]
    puts shortstat.first.strip
    puts COMPARE_FORMAT % [from,to]
    puts "Migrations:", migrations if migrations.any?
    puts "Pull Requests:", prs.map { |x| PR_FORMAT % x } if prs.any?
    puts "Commits:", commits if prs.size.zero?
  else
    puts "redeployed %s %s" % [from, time_delta]
  end
  puts
end

last_n_deploys = 30
deploys = `git tag -l | grep production`.split(/\n/).drop(1)
deploys = deploys.last(1+last_n_deploys) if last_n_deploys
deploys.each_cons(2) do |(from, to)|
  deploy(from, to)
end

# deploy("production", "staging")
