
class UserProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit
    @profile =  current_user.profile
  end

  def update
    @profile = Profile.find(params[:user_id])
    if @profile.update(profile_param)
      flash[:notice] = '変更しました'
      redirect_to mypage_path
    else
      render :edit
    end
  end

  private

  def profile_param
    params.require(:profile).permit(:nickname, :profile_comment, :avatar)
  end
end
