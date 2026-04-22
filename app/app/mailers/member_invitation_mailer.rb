class MemberInvitationMailer < ApplicationMailer
  def invite(membership)
    @membership = membership
    @user = membership.user
    @workspace = membership.workspace
    @login_url = new_user_session_url

    mail(
      to: @user.email,
      subject: "You've been added to #{@workspace.name} on Promptly"
    )
  end
end
