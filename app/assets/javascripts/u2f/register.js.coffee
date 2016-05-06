# Register U2F (universal 2nd factor) devices for users to authenticate with.
#
# State Flow #1: setup -> in_progress -> registered -> POST to server
# State Flow #2: setup -> in_progress -> error -> setup

class @U2FRegister
  constructor: (@container, @templates_container, u2f_params, @authenticity_token) ->
    @app_id = u2f_params.app_id
    @register_requests = u2f_params.register_requests
    @sign_requests = u2f_params.sign_requests

  start: () =>
    if U2FUtil.isU2FSupported()
      @renderSetup()
    else
      @renderNotSupported()

  register: () =>
    u2f.register(@app_id, @register_requests, @sign_requests, (response) =>
      if response.errorCode
        error = new U2FError(response.errorCode)
        @renderError(error);
      else
        @renderRegistered(JSON.stringify(response))
    , 10)

  #############
  # Rendering #
  #############

  templates: {
    "notSupported": "#registerU2F_notSupported",
    "setup": '#registerU2F_setup',
    "inProgress": '#registerU2F_inProgress',
    "error": '#registerU2F_error',
    "registered": '#registerU2F_registered',
  }

  renderTemplate: (name, params) =>
    template_string = @templates_container.find(@templates[name]).html()
    template = _.template(template_string)
    @container.html(template(params))

  renderSetup: () =>
    @renderTemplate('setup')
    @container.find('#setupU2FDevice').click(@renderInProgress)

  renderInProgress: () =>
    @renderTemplate('inProgress')
    @register()

  renderError: (error) =>
    @renderTemplate('error', {error_message: error.message()})
    @container.find('#U2FTryAgain').click(@renderSetup)

  renderRegistered: (device_response) =>
    @renderTemplate('registered', {device_response: device_response, authenticity_token: @authenticity_token})

  renderNotSupported: () =>
    @renderTemplate('notSupported')
