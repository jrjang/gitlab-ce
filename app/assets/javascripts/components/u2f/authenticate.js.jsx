// Authenticate users using U2F (universal 2nd factor) devices.
//
// State Flow #1: setup -> in_progress -> authentication -> POST to server
// State Flow #2: setup -> in_progress -> error -> setup

var U2FAuthenticate = React.createClass({

  getInitialState: function() {
    return {status: "setup"};
  },

  reset: function() {
    this.setState({status: "setup"});
  },

  inProgress: function(event) {
    this.setState({status: "in_progress"});
    u2f.sign(this.props.appId, this.props.challenges, this.props.signRequests, (function(authResponse) {
      if (authResponse.errorCode) {
        this.authError(authResponse.errorCode);
      } else {
        this.setState({deviceResponse: JSON.stringify(authResponse), status: "authentication"});
      }
    }).bind(this), 10);
  },

  // List of error codes: https://developers.yubico.com/U2F/Libraries/Client_error_codes.html
  authError: function(errorCode) {
    this.setState({status: "error", errorMessage: "There was a problem communicating with your device."});
  },

  render: function() {
    if (!U2FUtil.isU2FSupported()) {
      return (
        <p>Your browser doesn't support U2F. Please use Google Chrome (version 41 or newer).</p>
      );
    }
    else if (this.state.status == "setup") {
      return (
        <div>
          <p>Insert your security key (if you haven't already), and press the button below.</p>
          <a className="btn btn-info" id="loginU2FDevice" onClick={this.inProgress}>Login Via U2F Device</a>
        </div>
      );
    }
    else if (this.state.status == "in_progress") {
      return (
        <p>Trying to communicate with your device. Plug it in (if you haven't already) and press the button on the device now.</p>
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
    else if (this.state.status == "authentication") {
      return (
        <div>
          <p>We heard back from your U2F device. Click this button to authenticate with the GitLab server.</p>
          <form id="authenticate_u2f" action="/users/sign_in" acceptCharset="UTF-8" method="post">
            <input type="hidden" name="authenticity_token" value={this.props.authenticity_token}  />
            <input type="hidden" name="user[device_response]" id="device_response" className="device_response form-control" required="required" value={this.state.deviceResponse} />
            <input type="submit" name="commit" value="Authenticate via U2F Device" className="btn btn-success" id="authenticateU2FDevice"/>
          </form>
        </div>
      );
    }
  }
});



