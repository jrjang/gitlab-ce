class Profiles::TwoFactorAuthsController < Profiles::ApplicationController
  skip_before_action :check_2fa_requirement

  def show
    unless current_user.otp_secret
      current_user.otp_secret = User.generate_otp_secret(32)
    end

    unless current_user.otp_grace_period_started_at && two_factor_grace_period
      current_user.otp_grace_period_started_at = Time.current
    end

    current_user.save! if current_user.changed?

    if two_factor_authentication_required? && !current_user.two_factor_enabled?
      if two_factor_grace_period_expired?
        flash.now[:alert] = 'You must enable Two-factor Authentication for your account.'
      else
        grace_period_deadline = current_user.otp_grace_period_started_at + two_factor_grace_period.hours
        flash.now[:alert] = "You must enable Two-factor Authentication for your account before #{l(grace_period_deadline)}."
      end
    end

    @qr_code = build_qr_code

    setup_u2f_registration
  end

  def create
    if current_user.validate_and_consume_otp!(params[:pin_code])
      current_user.otp_required_for_login = true
      @codes = current_user.generate_otp_backup_codes!
      current_user.save!

      render 'create'
    else
      @error = 'Invalid pin code'
      @qr_code = build_qr_code

      render 'show'
    end
  end

  def create_u2f
    u2f = U2F::U2F.new(u2f_app_id)
    response = U2F::RegisterResponse.load_from_json(params[:device_response])
    reg = u2f.register!(session[:challenges], response)
    current_user.u2f_registrations.create!(certificate: reg.certificate, key_handle: reg.key_handle,
                                           public_key: reg.public_key, counter: reg.counter)
    session.delete(:challenges)
    redirect_to profile_account_path, notice: "Your U2F device was registered!"
  rescue StandardError => e
    @u2f_error = "Unable to register: #{e.class.name}"
    @qr_code = build_qr_code
    setup_u2f_registration
    render :show
  end

  def codes
    @codes = current_user.generate_otp_backup_codes!
    current_user.save!
  end

  def destroy
    current_user.disable_two_factor!

    redirect_to profile_account_path
  end

  def skip
    if two_factor_grace_period_expired?
      redirect_to new_profile_two_factor_auth_path, alert: 'Cannot skip two factor authentication setup'
    else
      session[:skip_tfa] = current_user.otp_grace_period_started_at + two_factor_grace_period.hours
      redirect_to root_path
    end
  end

  private

  def build_qr_code
    issuer = "#{issuer_host} | #{current_user.email}"
    uri = current_user.otp_provisioning_uri(current_user.email, issuer: issuer)
    RQRCode::render_qrcode(uri, :svg, level: :m, unit: 3)
  end

  def issuer_host
    Gitlab.config.gitlab.host
  end

  def setup_u2f_registration
    @app_id = u2f_app_id
    u2f = U2F::U2F.new(@app_id)
    @registrations = current_user.u2f_registrations
    @registration_requests = u2f.registration_requests
    @sign_requests = u2f.authentication_requests(@registrations.map(&:key_handle))
    session[:challenges] = @registration_requests.map(&:challenge)

    # This is only used for the acceptance test covering this feature
    gon.push(u2f: { challenges: session[:challenges], app_id: @app_id })
  end
end
