class @U2FError
  constructor: (@error_code) ->

  message: () =>
    switch @error_code
      when 4 then "This device has already been registered with us."
      else "There was a problem communicating with your device."
