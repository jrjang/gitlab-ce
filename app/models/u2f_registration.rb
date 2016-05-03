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
#
# Registration information for U2F (universal 2nd factor) devices, like Yubikeys

class U2fRegistration < ActiveRecord::Base
  belongs_to :user

  def self.authenticate(user, app_id, json_response, challenges)
    response = U2F::SignResponse.load_from_json(json_response)
    registration = user.u2f_registrations.find_by_key_handle(response.key_handle)

    u2f = U2F::U2F.new(app_id)

    if registration
      u2f.authenticate!(challenges, response,  Base64.decode64(registration.public_key), registration.counter)
      registration.update(counter: response.counter)
      true
    end
  rescue U2F::Error
    false
  end
end
