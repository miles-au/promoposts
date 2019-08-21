class OverlaysController < ApplicationController
	before_action :logged_in_user

	def show
		@overlays = current_user.overlays
	  @new_overlay = current_user.overlays.build
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
		@overlay = Overlay.find(params[:id])
		@overlay.destroy
    flash[:success] = "Overlay deleted"
    redirect_to overlays_path
	end

	private
	  	def overlay_params
	      params.require(:overlay).permit(:picture, :category, :name)
	    end
end
