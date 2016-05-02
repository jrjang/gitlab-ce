#= require react
#= require components/u2f/register
#= require components/u2f/util
#= require bowser
#= require ./mock_u2f_device

describe 'U2FRegister', ->
  U2FUtil.enableTestMode()
  TestUtils = React.addons.TestUtils

  beforeEach ->
    @u2f_device = new MockU2FDevice
    @component = TestUtils.renderIntoDocument(React.createElement(U2FRegister))

  it 'allows registering a U2F device', ->
    setup_button = TestUtils.findRenderedDOMComponentWithClass(@component, 'btn')
    expect(setup_button.textContent).toBe('Setup New U2F Device')
    TestUtils.Simulate.click(setup_button)

    in_progress_message = TestUtils.findRenderedDOMComponentWithTag(@component, 'p')
    expect(in_progress_message.textContent).toContain("Trying to communicate with your device")

    @u2f_device.respond_to_register_request({device_data: "this is data from the device"})
    registered_message = TestUtils.findRenderedDOMComponentWithTag(@component, 'p')
    device_response = TestUtils.findRenderedDOMComponentWithClass(@component, 'device_response')
    expect(registered_message.textContent).toContain("Your device was successfully set up!")
    expect(device_response.value).toBe('{"device_data":"this is data from the device"}')

  describe "errors", ->
    it "doesn't allow the same device to be registered twice (for the same user", ->
      setup_button = TestUtils.findRenderedDOMComponentWithClass(@component, 'btn')
      TestUtils.Simulate.click(setup_button)
      @u2f_device.respond_to_register_request({errorCode: 4})
      error_message = TestUtils.findRenderedDOMComponentWithTag(@component, 'p')
      expect(error_message.textContent).toContain("already been registered with us")

    it "displays an error message for other errors", ->
      setup_button = TestUtils.findRenderedDOMComponentWithClass(@component, 'btn')
      TestUtils.Simulate.click(setup_button)
      @u2f_device.respond_to_register_request({errorCode: "error!"})
      error_message = TestUtils.findRenderedDOMComponentWithTag(@component, 'p')
      expect(error_message.textContent).toContain("There was a problem communicating with your device")

    it "allows retrying registration after an error", ->
      setup_button = TestUtils.findRenderedDOMComponentWithClass(@component, 'btn')
      TestUtils.Simulate.click(setup_button)
      @u2f_device.respond_to_register_request({errorCode: "error!"})
      retry_button = TestUtils.findRenderedDOMComponentWithClass(@component, 'btn')
      TestUtils.Simulate.click(retry_button)

      setup_button = TestUtils.findRenderedDOMComponentWithClass(@component, 'btn')
      TestUtils.Simulate.click(setup_button)
      @u2f_device.respond_to_register_request({device_data: "this is data from the device"})
      registered_message = TestUtils.findRenderedDOMComponentWithTag(@component, 'p')
      expect(registered_message.textContent).toContain("Your device was successfully set up!")