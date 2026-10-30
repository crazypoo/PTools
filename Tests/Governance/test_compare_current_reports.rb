#!/usr/bin/env ruby
# PR56: regression tests for normalized report comparison, including
# a material content drift where filenames themselves do not change.
require "fileutils"
require "tmpdir"
require "open3"
require "json"
require "minitest/autorun"

class CurrentReportComparisonTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  CHECKER = File.join(ROOT, "Scripts/Governance/compare_current_reports.rb")

  def with_reports
    Dir.mktmpdir("ptools-compare-fixture") do |root|
      left = File.join(root, "committed")
      right = File.join(root, "generated")
      [left, right].each { |directory| FileUtils.mkdir_p(directory) }
      yield left, right
    end
  end

  def compare(left, right)
    Open3.capture3("ruby", CHECKER, left, right)
  end

  def test_different_content_reports_exact_changed_file
    with_reports do |left, right|
      File.write(File.join(left, "metrics.json"), JSON.generate({"count" => 4}))
      File.write(File.join(right, "metrics.json"), JSON.generate({"count" => 5}))
      stdout, stderr, status = compare(left, right)
      refute status.success?
      assert_includes stdout + stderr, "FAIL [CURRENT_REPORT_DRIFT]"
      assert_includes stdout + stderr, "changed report: metrics.json"
    end
  end

  def test_only_commit_local_provenance_is_normalized
    with_reports do |left, right|
      File.write(File.join(left, "metrics.json"), JSON.generate({"generatedAt" => "old", "count" => 4}))
      File.write(File.join(right, "metrics.json"), JSON.generate({"generatedAt" => "new", "count" => 4}))
      _out, err, status = compare(left, right)
      assert status.success?, err
    end
  end

  def test_missing_and_unexpected_reports_are_reported
    with_reports do |left, right|
      File.write(File.join(left, "retired.md"), "stale")
      File.write(File.join(right, "new.md"), "latest")
      stdout, stderr, status = compare(left, right)
      refute status.success?
      assert_includes stdout + stderr, "missing generated report: retired.md"
      assert_includes stdout + stderr, "unexpected generated report: new.md"
    end
  end
end
