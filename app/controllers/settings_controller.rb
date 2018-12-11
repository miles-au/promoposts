class SettingsController < ApplicationController
  
  def update_settings
  	@user = User.find(params[:id])
  	@setting = @user.setting
    @setting.update_attributes(settings_params)

    if @setting.save
      flash[:success] = "Settings updated"
      redirect_to @user
    else
      flash[:success] = "Sorry, we are unable to update your settings"
      redirect_to user_settings_path(:id => current_user)
    end
    
  end

  private

  	def settings_params
      params.require(:setting).permit(:email_for_replies, :user_id)
    end

end
