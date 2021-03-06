class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :async,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable
         
  after_create :create_account
  
  validate :email_is_unique, on: :create

  # def confirmation_required?
  #   false
  # end
  
  private
  
  def email_is_unique
    
    return false unless self.errors[:email].empty?
    
    unless Account.find_by_email(email).nil?
      errors.add(:email, " is already taken")
    end
  end
  
  def create_account
    account = Account.new(email: email)
    account.save!
  end         

end


