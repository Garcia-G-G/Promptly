require "test_helper"

class DatasetRowTest < ActiveSupport::TestCase
  setup do
    @dataset = datasets(:summarizer_cases)
  end

  test "valid with proper input_vars" do
    row = @dataset.dataset_rows.build(input_vars: { "language" => "en", "tone" => "formal" })
    assert row.valid?
  end

  test "invalid without input_vars" do
    row = @dataset.dataset_rows.build(input_vars: nil)
    assert_not row.valid?
  end

  test "rejects non-hash input_vars" do
    row = @dataset.dataset_rows.build(input_vars: [ "not", "a", "hash" ])
    assert_not row.valid?
    assert_includes row.errors[:input_vars].join, "must be a JSON object"
  end

  test "rejects oversized input_vars" do
    huge = { "key" => "x" * 200_000 }
    row = @dataset.dataset_rows.build(input_vars: huge)
    assert_not row.valid?
    assert_match(/exceeds/, row.errors[:input_vars].join)
  end

  test "rejects non-array tags" do
    row = @dataset.dataset_rows.build(input_vars: { "a" => "b" }, tags: "not-array")
    assert_not row.valid?
    assert_match(/array of strings/i, row.errors[:tags].join)
  end

  test "accepts string array tags" do
    row = @dataset.dataset_rows.build(input_vars: { "a" => "b" }, tags: [ "tag1", "tag2" ])
    assert row.valid?
  end

  test "parent counter cache updates on create" do
    initial = @dataset.dataset_rows_count
    @dataset.dataset_rows.create!(input_vars: { "x" => "1" })
    assert_equal initial + 1, @dataset.reload.dataset_rows_count
  end
end
