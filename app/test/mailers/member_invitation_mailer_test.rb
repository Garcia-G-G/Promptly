require "test_helper"

class MemberInvitationMailerTest < ActionMailer::TestCase
  test "invite renders the membership invitation" do
    membership = memberships(:dev_demo)

    email = MemberInvitationMailer.invite(membership)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ membership.user.email ], email.to
    assert_match membership.workspace.name, email.subject
    body = email.body.encoded
    assert_match(/added to/i, body)
    assert_match membership.role, body
  end
end
