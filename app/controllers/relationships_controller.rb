class RelationshipsController < ApplicationController
  before_action :logged_in_user

  def create
    @user = User.find(params[:followed_id])
    current_user.follow(@user)

    #create notification
    @notification = Notification.new(:user_id => @user.id, :message => "#{current_user.name} is now following you.", :url => user_url(current_user) )
    @notification.save!

    #send email notification
    @user.send_followed_email(current_user)

    respond_to do |format|
      format.html { redirect_to @user }
      format.js
    end
  end

  def destroy
    @user = Relationship.find(params[:id]).followed
    current_user.unfollow(@user)
    respond_to do |format|
      format.html { redirect_to @user }
      format.js
    end
  end
  
end