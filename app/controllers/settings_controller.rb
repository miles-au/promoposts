class SettingsController < ApplicationController
  
  # def update_settings
  # 	@user = User.find(params[:id])
  # 	@setting = @user.setting
  #   @setting.update_attributes(settings_params)

  #   if @setting.save
  #     flash[:success] = "Settings updated"
  #     redirect_to user_settings_path(:id => current_user)
  #   else
  #     flash[:success] = "Sorry, we are unable to update your settings"
  #     redirect_to user_settings_path(:id => current_user)
  #   end
  # end

  def update_topics
    topic = Topic.find(params[:topic])

    if current_user.topics.include?(topic)
      #unsubscribe from this topic
      current_user.delete_topic(topic)
    elsif current_user.topics.count < Topic.topics_limit
      #subscribe to topic
      current_user.add_topic(topic)
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  	def settings_params
      params.require(:setting).permit(:email_for_replies, :email_when_followed, :email_when_new_question, :user_id)
    end

end
