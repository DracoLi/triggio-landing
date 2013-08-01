class WaitList < ActiveRecord::Base
  validates :company_name, presence: true,
                           uniqueness: true,
                           length: { minimum: 3 }
  validates :email, email_format: true, 
                    presence: true,
                    uniqueness: true,
                    length: { maximum: 255 }
end