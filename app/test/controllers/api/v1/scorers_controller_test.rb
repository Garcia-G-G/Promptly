require "test_helper"

class Api::V1::ScorersControllerTest < ActionDispatch::IntegrationTest
  test "GET /scorers returns project-scoped list" do
    get api_v1_scorers_path, headers: api_headers
    assert_response :success
    body = response.parsed_body
    assert_kind_of Array, body
  end

  test "POST /scorers creates scorer" do
    post api_v1_scorers_path,
      params: { name: "new-scorer", scorer_type: "exact_match", content: "expected" }.to_json,
      headers: api_headers
    assert_response :created
    assert_equal "new-scorer", response.parsed_body["name"]
    assert_equal "exact_match", response.parsed_body["scorer_type"]
  end

  test "PATCH /scorers/:id updates scorer" do
    scorer = scorers(:exact_match_scorer)
    patch api_v1_scorer_path(id: scorer.id),
      params: { content: "new expected" }.to_json,
      headers: api_headers
    assert_response :success
    assert_equal "new expected", response.parsed_body["content"]
  end

  test "DELETE /scorers/:id soft-deletes scorer" do
    scorer = scorers(:exact_match_scorer)
    delete api_v1_scorer_path(id: scorer.id), headers: api_headers
    assert_response :success
    refute response.parsed_body["active"]
    scorer.reload
    assert_not scorer.active?
  end
end
