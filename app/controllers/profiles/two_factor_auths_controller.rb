class Profiles::TwoFactorAuthsController < Profiles::ApplicationController
  skip_before_action :check_2fa_requirement

  def new
    unless current_user.otp_secret
      current_user.otp_secret = User.generate_otp_secret(32)
    end

    unless current_user.otp_grace_period_started_at && two_factor_grace_period
      current_user.otp_grace_period_started_at = Time.current
    end

    current_user.save! if current_user.changed?

    if two_factor_authentication_required?
      if two_factor_grace_period_expired?
        flash.now[:alert] = 'You must enable Two-factor Authentication for your account.'
      else
        grace_period_deadline = current_user.otp_grace_period_started_at + two_factor_grace_period.hours
        flash.now[:alert] = "You must enable Two-factor Authentication for your account before #{l(grace_period_deadline)}."
      end
    end

    @qr_code = build_qr_code

    u2f = U2F::U2F.new(request.base_url)
    #key_handles = Registration.map(&:key_handle)
    registration_requests = u2f.registration_requests
    sign_requests = u2f.authentication_requests([])
    session[:challenges] = registration_requests.map(&:challenge)

    gon.push(u2f_request: {app_id: request.base_url, registration_requests: registration_requests})
  end

  def create
    if current_user.validate_and_consume_otp!(params[:pin_code])
      current_user.two_factor_enabled = true
      @codes = current_user.generate_otp_backup_codes!
      current_user.save!

      render 'create'
    else
      @error = 'Invalid pin code'
      @qr_code = build_qr_code

      render 'new'
    end
  end

  def create_u2f
    begin
      u2f = U2F::U2F.new(request.base_url)
      response = U2F::RegisterResponse.load_from_json(params[:device_response])
      u2f.register!(session[:challenges], response)
    rescue Exception => e
      @u2f_error = "Unable to register: #{e.class.name}"
      @qr_code = build_qr_code
      render :new
    ensure
      session.delete(:challenges)
    end
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
end
