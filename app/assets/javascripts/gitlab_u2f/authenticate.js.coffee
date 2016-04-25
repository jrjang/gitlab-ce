class @GitLabU2FAuthenticate
  constructor: (request, @form) ->
    @app_id = request.app_id
    @sign_requests = request.sign_requests
    @challenges = request.challenges
    @device_response_field = $(@form).find('#device_response')

  run: () =>
    if @device_response_field
      u2f.sign @app_id, @challenges, @sign_requests, (sign_response) =>
        if sign_response.errorCode
          console.log 'Registration error: ' + sign_response.errorCode
        else
          @device_response_field.val(JSON.stringify(sign_response))
          @form.removeClass('hidden')
          console.log sign_response