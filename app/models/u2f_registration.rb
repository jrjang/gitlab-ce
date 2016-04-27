# == Schema Information
#
# Table name: u2f_registrations
#
#  id          :integer          not null, primary key
#  certificate :text
#  key_handle  :string
#  public_key  :string
#  counter     :integer
#  user_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

# Registration information for U2F devices, like Yubikeys

class U2fRegistration < ActiveRecord::Base
  belongs_to :user

  def self.authenticate(user, json_response, challenges)
    response = U2F::SignResponse.load_from_json(json_response)
    registration = U2fRegistration.find_by_key_handle(response.key_handle)

    u2f = U2F::U2F.new('https://localhost:3443')

    if registration
      u2f.authenticate!(challenges, response,  Base64.decode64(registration.public_key), registration.counter)
    end

    registration.update(counter: response.counter)

    true
  rescue U2F::Error
    false
  end
end
