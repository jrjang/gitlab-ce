#= require react
#= require components/u2f/authenticate
#= require components/u2f/util
#= require bowser
#= require ./mock_u2f_device

describe 'U2FAuthenticate', ->
  U2FUtil.enableTestMode()
  TestUtils = React.addons.TestUtils

  beforeEach ->
    @u2f_device = new MockU2FDevice
    @component = TestUtils.renderIntoDocument(React.createElement(U2FAuthenticate))

  it 'allows authenticating via a U2F device', ->
    setup_button = TestUtils.findRenderedDOMComponentWithClass(@component, 'btn')
    setup_message = TestUtils.findRenderedDOMComponentWithTag(@component, 'p')
    expect(setup_message.textContent).toContain('Insert your security key')
    expect(setup_button.textContent).toBe('Login Via U2F Device')
    TestUtils.Simulate.click(setup_button)

    in_progress_message = TestUtils.findRenderedDOMComponentWithTag(@component, 'p')
    expect(in_progress_message.textContent).toContain("Trying to communicate with your device")

    @u2f_device.respond_to_authenticate_request({device_data: "this is data from the device"})
    authenticated_message = TestUtils.findRenderedDOMComponentWithTag(@component, 'p')
    device_response = TestUtils.findRenderedDOMComponentWithClass(@component, 'device_response')
    expect(authenticated_message.textContent).toContain("Click this button to authenticate with the GitLab server")
    expect(device_response.value).toBe('{"device_data":"this is data from the device"}')

  describe "errors", ->
    it "displays an error message", ->
      setup_button = TestUtils.findRenderedDOMComponentWithClass(@component, 'btn')
      TestUtils.Simulate.click(setup_button)
      @u2f_device.respond_to_authenticate_request({errorCode: "error!"})
      error_message = TestUtils.findRenderedDOMComponentWithTag(@component, 'p')
      expect(error_message.textContent).toContain("There was a problem communicating with your device")

    it "allows retrying authentication after an error", ->
      setup_button = TestUtils.findRenderedDOMComponentWithClass(@component, 'btn')
      TestUtils.Simulate.click(setup_button)
      @u2f_device.respond_to_authenticate_request({errorCode: "error!"})
      retry_button = TestUtils.findRenderedDOMComponentWithClass(@component, 'btn')
      TestUtils.Simulate.click(retry_button)

      setup_button = TestUtils.findRenderedDOMComponentWithClass(@component, 'btn')
      TestUtils.Simulate.click(setup_button)
      @u2f_device.respond_to_authenticate_request({device_data: "this is data from the device"})
      authenticated_message = TestUtils.findRenderedDOMComponentWithTag(@component, 'p')
      expect(authenticated_message.textContent).toContain("Click this button to authenticate with the GitLab server")