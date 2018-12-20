class NotificationsController < ApplicationController
	def all
	  @notifications = current_user.notifications.paginate(:page => params[:page], :per_page => 20)
	end

	def mark_read
		@user = User.find(params[:user_id])
		@notifications = @user.unread_notifications

		puts "UNREAD: #{@notifications}"

		@notifications.each do |notification|
			notification.read = true
			notification.save
		end

		head :ok, content_type: "text/html"
	end
end
