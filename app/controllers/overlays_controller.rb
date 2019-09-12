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
      flash.now[:success] = "Overlay created"
    else
    	flash.now[:danger] = "Unable to create overlay"
    end
    @overlays = current_user.overlays
    @new_overlay = current_user.overlays.build
	  respond_to do |format|
      format.html
      format.js { render 'render_overlays_container.js.erb' }
    end
	end

	def destroy
		@overlay = Overlay.find(params[:id])
		@overlay.destroy
    flash.now[:success] = "Overlay deleted"
    @overlays = current_user.overlays
    @new_overlay = current_user.overlays.build
    respond_to do |format|
      format.html
      format.js { render 'render_overlays_container.js.erb' }
    end
	end

	def default_overlay
		if params[:id] == "none"
			current_user.setting.default_overlay_id = nil
			current_user.setting.default_overlay_location = nil
		elsif current_user.overlays.find(params[:id])
			current_user.setting.default_overlay_id = params[:id]
			current_user.setting.default_overlay_location = params[:location]
		end
		if current_user.setting.save
			flash.now[:success] = "Default overlay updated"
		else
			flash.now[:danger] = "Unable to update default overlay"
		end
		@overlays = current_user.overlays
		@new_overlay = current_user.overlays.build
		respond_to do |format|
      format.html
      format.js { render 'render_overlays_container.js.erb' }
    end
	end

	private
  	def overlay_params
      params.require(:overlay).permit(:picture, :category, :name, :location)
    end
    
end
