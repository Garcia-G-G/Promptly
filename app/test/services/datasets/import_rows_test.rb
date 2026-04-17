require "test_helper"

class Datasets::ImportRowsTest < ActiveSupport::TestCase
  test "imports rows" do
    ds = Dataset.create!(project: projects(:playground), name: "import-test")
    rows = [
      { input_vars: { "lang" => "en" }, expected_output: "Hello", tags: [ "core" ] },
      { input_vars: { "lang" => "es" }, expected_output: "Hola", tags: [] }
    ]

    count = Datasets::ImportRows.call(dataset: ds, rows: rows)
    assert_equal 2, count
    assert_equal 2, ds.dataset_rows.count
  end

  test "rejects more than 10000 rows" do
    ds = Dataset.create!(project: projects(:playground), name: "too-many")
    rows = 10_001.times.map { { input_vars: { "x" => "y" } } }

    assert_raises ArgumentError do
      Datasets::ImportRows.call(dataset: ds, rows: rows)
    end
  end
end
