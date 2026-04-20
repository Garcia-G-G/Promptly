require "test_helper"

class Datasets::CreateTest < ActiveSupport::TestCase
  test "creates a dataset" do
    ds = Datasets::Create.call(project: projects(:playground), name: "new-ds", description: "A test")
    assert ds.persisted?
    assert_equal "new-ds", ds.name
  end

  test "duplicate name raises" do
    assert_raises ActiveRecord::RecordInvalid do
      Datasets::Create.call(project: projects(:playground), name: "summarizer-test-cases")
    end
  end
end
