require "test_helper"

class DatasetTest < ActiveSupport::TestCase
  test "valid dataset" do
    ds = Dataset.new(project: projects(:playground), name: "test-ds")
    assert ds.valid?
  end

  test "requires name" do
    ds = Dataset.new(project: projects(:playground), name: nil)
    assert_not ds.valid?
  end

  test "name unique per project" do
    assert_raises ActiveRecord::RecordInvalid do
      Dataset.create!(project: projects(:playground), name: "summarizer-test-cases")
    end
  end

  test "has many dataset_rows" do
    assert_respond_to datasets(:summarizer_cases), :dataset_rows
  end
end
