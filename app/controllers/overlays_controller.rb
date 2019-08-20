class OverlaysController < ApplicationController
	before_action :logged_in_user

	def show
	  @new_overlay = current_user.overlays.build
	  @overlays = current_user.overlays
	end

	def create
		@overlay = current_user.overlays.build(overlay_params)
		@overlay.permissions = "private"
    if @overlay.save
      flash[:success] = "Overlay created"
    else
    	flash[:danger] = "Unable to create overlay"
    end
	  redirect_to '/overlays'
	end

	def destroy

	end

	private
	  	def overlay_params
	      params.require(:overlay).permit(:picture, :category, :name)
	    end
end
