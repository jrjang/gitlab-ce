# == AuthenticatesWithTwoFactor
#
# Controller concern to handle two-factor authentication
#
# Upon inclusion, skips `require_no_authentication` on `:create`.
module AuthenticatesWithTwoFactor
  extend ActiveSupport::Concern

  included do
    # This action comes from DeviseController, but because we call `sign_in`
    # manually, not skipping this action would cause a "You are already signed
    # in." error message to be shown upon successful login.
    skip_before_action :require_no_authentication, only: [:create]
  end

  # Store the user's ID in the session for later retrieval and render the
  # two factor code prompt
  #
  # The user must have been authenticated with a valid login and password
  # before calling this method!
  #
  # user - User record
  #
  # Returns nil
  def prompt_for_two_factor(user)
    session[:otp_user_id] = user.id

    @key_handles = user.u2f_registrations.pluck(:key_handle)
    u2f = U2F::U2F.new('https://localhost:3443')

    if @key_handles.present?
      sign_requests = u2f.authentication_requests(@key_handles)
      challenges = sign_requests.map(&:challenge)
      session[:challenges] = challenges
      gon.push(u2f_request: {sign_requests: sign_requests, app_id: "https://localhost:3443", challenges: challenges})
    end


    render 'devise/sessions/two_factor' and return
  end
end
