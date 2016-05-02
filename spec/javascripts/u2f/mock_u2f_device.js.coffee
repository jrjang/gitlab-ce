class @MockU2FDevice
  constructor: () ->
    window.u2f ||= {}

    window.u2f.register = (app_id, register_requests, sign_requests, callback) =>
      @register_callback = callback

    window.u2f.sign = (app_id, challenges, sign_requests, callback) =>
      @authenticate_callback = callback

  respond_to_register_request: (params) =>
    @register_callback(params)

  respond_to_authenticate_request: (params) =>
    @authenticate_callback(params)