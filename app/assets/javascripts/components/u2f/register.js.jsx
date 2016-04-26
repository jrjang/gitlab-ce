// State Flow #1: setup -> in_progress -> registration -> POST to server
// State Flow #2: setup -> in_progress -> error -> setup

var U2FRegister = React.createClass({

  getInitialState: function() {
    return {status: "setup"};
  },

  reset: function() {
    this.setState({status: "setup"});
  },

  inProgress: function(event) {
    this.setState({status: "in_progress"});
    u2f.register(this.props.appId, this.props.registerRequests, this.props.signRequests, (function(registerResponse) {
      if (registerResponse.errorCode) {
        this.registerError(registerResponse.errorCode);
      } else {
        this.setState({deviceResponse: JSON.stringify(registerResponse), status: "registration"});
      }
    }).bind(this), 10);
  },

  // List of error codes: https://developers.yubico.com/U2F/Libraries/Client_error_codes.html
  registerError: function(errorCode) {
    if(errorCode == 4) {
      this.setState({status: "error", errorMessage: "This device has already been registered with us."});
    } else {
      this.setState({status: "error", errorMessage: "There was a problem communicating with your device."});
    }
  },

  render: function() {
    if (this.state.status == "setup") {
      return (
        <div className="row append-bottom-10">
          <div className="col-md-3">
            <a className="btn btn-info" onClick={this.inProgress}>Setup New U2F Device</a>
          </div>
          <div className="col-md-9">
            <p>Your U2F device needs to be set up. Plug it in (if not already) and click the button on the left.</p>
          </div>
        </div>
      );
    }
    else if (this.state.status == "in_progress") {
      return (
        <p>Communicating with your device. Press the button on your device now.</p>
      );
    }
    else if (this.state.status == "error") {
      return (
        <div>
          <p>
            <span>{this.state.errorMessage}</span>
          </p>
          <a className="btn btn-warning" onClick={this.reset}>Try again?</a>
        </div>
      );
    }
    else if (this.state.status == "registration") {
      return (
        <div className="row append-bottom-10">
          <p>Your device was successfully set up! Click this button to register with the GitLab server.</p>
          <form action="/profile/two_factor_auth/create_u2f" acceptCharset="UTF-8" method="post">
            <input type="hidden" name="authenticity_token" value={this.props.authenticity_token}  />
            <input type="hidden" name="device_response" id="device_response" className="form-control" required="required" value={this.state.deviceResponse} />
            <input type="submit" name="commit" value="Register U2F Device" className="btn btn-success"/>
          </form>
        </div>
      );
    }
  }
});
