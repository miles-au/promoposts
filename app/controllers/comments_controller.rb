class CommentsController < ApplicationController
  before_action :logged_in_user, only: [:create, :reply]
  before_action :correct_or_admin_user,   only: [:destroy]

  def create
    @comment = params[:comment]
    @micropost = Micropost.find(@comment['micropost_id'])
    @comment = @micropost.comments.build(comment_params)

    if @comment.save
      flash[:success] = "Your comment is posted."
      @event = Event.new(user_id: current_user.id, passive_user_id: @micropost.user_id, micropost_id: @micropost.id, contribution: 'comment')
      @event.save!
      if @comment.head
        category = 'comment'
        recipient = Comment.find(@comment.head).user
      else
        category = 'post'
        recipient = @micropost.user
      end

      if recipient.verify_email && recipient.setting.email_for_replies
        @micropost.user.send_comment_mailer(recipient, @micropost, @comment.message, category, current_user)
      end

      redirect_to @micropost
    else
      puts 'FAILED'
      redirect_to micropost_path(@micropost.id), :flash => { :danger => @comment.errors.full_messages.join(', ') }
    end

  end

  def destroy
  	@comment = Comment.find(params[:id])
  	@micropost = @comment.micropost
  	@comment.message = '[deleted]'
  	@comment.save
  	redirect_to @micropost
  end

  def reply
  	@head = Comment.find(params[:head])
  	@user = current_user
  	@micropost = @head.micropost_id
  	@comment = Comment.new()
  	respond_to do |format|
        format.html
        format.js
    end
  end

  private

    def comment_params
      params.require(:comment).permit(:message, :user_id, :micropost_id, :score, :head)
    end
end
