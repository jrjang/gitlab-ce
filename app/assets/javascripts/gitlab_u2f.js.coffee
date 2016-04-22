#
#/**
# * Message types for messsages to/from the extension
#* @const
#* @enum {string}
#*/
#u2f.MessageTypes = {
#    'U2F_REGISTER_REQUEST': 'u2f_register_request',
#    'U2F_REGISTER_RESPONSE': 'u2f_register_response',
#    'U2F_SIGN_REQUEST': 'u2f_sign_request',
#    'U2F_SIGN_RESPONSE': 'u2f_sign_response',
#    'U2F_GET_API_VERSION_REQUEST': 'u2f_get_api_version_request',
#    'U2F_GET_API_VERSION_RESPONSE': 'u2f_get_api_version_response'
#};
#
#
#/**
#* Response status codes
#* @const
#* @enum {number}
#*/
#u2f.ErrorCodes = {
#    'OK': 0,
#    'OTHER_ERROR': 1,
#    'BAD_REQUEST': 2,
#    'CONFIGURATION_UNSUPPORTED': 3,
#    'DEVICE_INELIGIBLE': 4,
#    'TIMEOUT': 5
#};
#
#
#/**
#* A message for registration requests
#* @typedef {{
#*   type: u2f.MessageTypes,
#*   appId: ?string,
#*   timeoutSeconds: ?number,
#*   requestId: ?number
#* }}
#*/
#u2f.U2fRequest;
#
#
#/**
#* A message for registration responses
#* @typedef {{
#*   type: u2f.MessageTypes,
#*   responseData: (u2f.Error | u2f.RegisterResponse | u2f.SignResponse),
#*   requestId: ?number
#* }}
#*/
#u2f.U2fResponse;
#
#
#/**
#* An error object for responses
#* @typedef {{
#*   errorCode: u2f.ErrorCodes,
#*   errorMessage: ?string
#* }}
#*/
#u2f.Error;
#
#/**
#* Data object for a single sign request.
#* @typedef {enum {BLUETOOTH_RADIO, BLUETOOTH_LOW_ENERGY, USB, NFC}}
#*/
#u2f.Transport;
#
#
#/**
#* Data object for a single sign request.
#* @typedef {Array<u2f.Transport>}
#*/
#u2f.Transports;
#
#/**
#* Data object for a single sign request.
#* @typedef {{
#*   version: string,
#*   challenge: string,
#*   keyHandle: string,
#*   appId: string
#* }}
#*/
#u2f.SignRequest;
#
#
#/**
#* Data object for a sign response.
#* @typedef {{
#*   keyHandle: string,
#*   signatureData: string,
#*   clientData: string
#* }}
#*/
#u2f.SignResponse;
#
#
#/**
#* Data object for a registration request.
#* @typedef {{
#*   version: string,
#*   challenge: string
#* }}
#*/
#u2f.RegisterRequest;
#
#
#/**
#* Data object for a registration response.
#* @typedef {{
#*   version: string,
#*   keyHandle: string,
#*   transports: Transports,
#*   appId: string
#* }}
#*/
#u2f.RegisterResponse;
#
#
#/**
#* Data object for a registered key.
#* @typedef {{
#*   version: string,
#*   keyHandle: string,
#*   transports: ?Transports,
#*   appId: ?string
#* }}
#*/
#u2f.RegisteredKey;
#
#
#/**
#* Data object for a get API register response.
#* @typedef {{
#*   js_api_version: number
#* }}
#*/
#u2f.GetJsApiVersionResponse;


class @GitLabU2F
  constructor: (request, form) ->
    @appId = request.app_id;
    @register_requests = request.registration_requests
    @form = form
    @device_response_field = $(@form).find('#device_response')
    $ => this.register()

  register: =>
    u2f.register(@appId, @register_requests, [], (register_response) =>
      if register_response.errorCode
        console.log 'Registration error: ' + register_response.errorCode
      else
        @device_response_field.val(JSON.stringify(register_response))
        @form.removeClass('hidden')
        console.log register_response
    , 1000)

#  *
# Dispatches register requests to available U2F tokens. An array of sign
#  * requests identifies already registered tokens.
#  * If the JS API version supported by the extension is unknown, it first sends a
#  * message to the extension to find out the supported API version and then it sends
#  * the register request.
#  * @param {string=} appId
#  * @param {Array<u2f.RegisterRequest>} registerRequests
#  * @param {Array<u2f.RegisteredKey>} registeredKeys
#  * @param {function((u2f.Error|u2f.RegisterResponse))} callback
#  * @param {number=} opt_timeoutSeconds
#  */
#
