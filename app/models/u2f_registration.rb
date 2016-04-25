# Registration information for U2F devices, like Yubikeys

class U2fRegistration < ActiveRecord::Base
  belongs_to :user
end
