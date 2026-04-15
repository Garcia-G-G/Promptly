require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  test "generates key on create" do
    key = ApiKey.create!(workspace: workspaces(:demo), name: "test-key")
    assert key.raw_key.present?
    assert key.raw_key.start_with?("pk_")
    assert_equal key.raw_key[0, 8], key.key_prefix
    assert key.key_digest.present?
  end

  test "raw key is not persisted" do
    key = ApiKey.create!(workspace: workspaces(:demo), name: "test-key")
    reloaded = ApiKey.find(key.id)
    assert_nil reloaded.raw_key
  end

  test "authenticate returns key for valid raw key" do
    key = ApiKey.create!(workspace: workspaces(:demo), name: "test-key")
    found = ApiKey.authenticate(key.raw_key)
    assert_equal key, found
  end

  test "authenticate returns nil for invalid key" do
    assert_nil ApiKey.authenticate("pk_totally_bogus_key")
  end

  test "authenticate returns nil for blank key" do
    assert_nil ApiKey.authenticate("")
    assert_nil ApiKey.authenticate(nil)
  end

  test "authenticate returns nil for revoked key" do
    key = ApiKey.create!(workspace: workspaces(:demo), name: "test-key")
    key.revoke!
    assert_nil ApiKey.authenticate(key.raw_key)
  end

  test "authenticate updates last_used_at" do
    key = ApiKey.create!(workspace: workspaces(:demo), name: "test-key")
    assert_nil key.last_used_at

    ApiKey.authenticate(key.raw_key)
    key.reload
    assert_not_nil key.last_used_at
  end

  test "revoke sets revoked_at" do
    key = ApiKey.create!(workspace: workspaces(:demo), name: "test-key")
    assert_not key.revoked?

    key.revoke!
    assert key.revoked?
    assert_not_nil key.revoked_at
  end

  test "name length validation" do
    key = ApiKey.new(workspace: workspaces(:demo), name: "a" * 256)
    assert_not key.valid?
    assert_includes key.errors[:name], "is too long (maximum is 255 characters)"
  end

  test "digest is unique" do
    key1 = ApiKey.create!(workspace: workspaces(:demo), name: "key-1")
    key2 = ApiKey.new(workspace: workspaces(:demo), name: "key-2", key_digest: key1.key_digest, key_prefix: "pk_dupl")
    assert_not key2.valid?
  end
end
