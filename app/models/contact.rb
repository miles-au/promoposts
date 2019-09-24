class Contact < ApplicationRecord
  include ActiveModel::Validations

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, length: { maximum: 255 }
  validates :subject, presence: true, length: { maximum: 255 }
  validates :message, presence: true, length: { maximum: 1000 }
  validates :name, length: { maximum: 100 }

  attr_accessor :email, :subject, :message

  def new
    @message = Contact.new
  end

=begin
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
=end

  def persisted?
    false
  end

  def send_mailer(email, subject, message)
  	UserMailer.contacted(email, subject, message).deliver_now
  end

  def send_lead(email, subject, message, name, user)
    UserMailer.send_lead(email, subject, message, name, user).deliver_now
  end

  private
	  # Using a private method to encapsulate the permissible parameters is just a good pattern
	  # since you'll be able to reuse the same permit list between create and update. Also, you
	  # can specialize this method with per-user checking of permissible attributes.
	  def contact_params
	    params.require(:contact).permit(:email, :subject, :message)
	  end

end
