module U2fDeviceHelper
  def respond_to_u2f_registration
    app_id = page.evaluate_script('gon.u2f.app_id')
    challenges = page.evaluate_script('gon.u2f.challenges')

    u2f = U2F::FakeU2F.new(app_id)
    json_response = u2f.register_response(challenges[0])

    page.execute_script("
    u2f.register = function(appId, registerRequests, signRequests, callback) {
      callback(#{json_response});
    };
    ")
  end
end