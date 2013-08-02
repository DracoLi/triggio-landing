class WaitList < ActiveRecord::Base
  validates :company, presence: true,
                           length: { minimum: 2 }
  validates :email, email_format: true, 
                    presence: true,
                    length: { maximum: 255 }
end