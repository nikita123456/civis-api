class UsersController < ApplicationController
	def edit_invite
    @user = User.find_by_invitation_token(params[:invitation_token], true)
    redirect_to root_path unless @user.present?
  end

  def accepte_invite
    user = User.accept_invitation!(secure_params)
    sign_in(user)
    redirect_to organisation_setting_path(user.organisation_id)
  end

  private

  def secure_params
    params.require(:user).permit(:profile_picture, :first_name, :last_name, :password, :invitation_token)
  end
end