class U2fRegistrations::CreateService
  def initialize(user, params)
    @user = user
    @params = params
  end

  def execute
    response = U2F::RegisterResponse.load_from_json(@params[:device_response])
    registration = u2f.register!(@params[:challenges], response)
    @user.u2f_registrations.create!(certificate: registration.certificate, key_handle: registration.key_handle,
                                    public_key: registration.public_key, counter: registration.counter)
    @success = true
  rescue StandardError => error
    @error = error
  end

  def success?
    @success
  end

  def error_message
    if @error
      "Couldn't register your U2F device: #{@error.message} (#{@error.class.name})"
    else
      "Couldn't register your U2F device"
    end
  end

  private

  def u2f
    @u2f ||= U2F::U2F.new(@params[:app_id])
  end
end
