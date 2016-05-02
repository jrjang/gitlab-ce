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
    @app_id = u2f_app_id
    u2f = U2F::U2F.new(@app_id)

    if @key_handles.present?
      @sign_requests = u2f.authentication_requests(@key_handles)
      @challenges = @sign_requests.map(&:challenge)
      session[:challenges] = @challenges

      # This is only used for the acceptance test covering this feature
      gon.push(u2f: { challenges: @challenges, app_id: @app_id })
    end


    render 'devise/sessions/two_factor' and return
  end
end
