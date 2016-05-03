require 'spec_helper'

feature 'Using U2F (Universal 2nd Factor) Devices for Authentication', feature: true, js: true do
  def register_u2f_device(u2f_device = nil)
    u2f_device ||= FakeU2fDevice.new(page)
    u2f_device.respond_to_u2f_registration
    find('#setupU2FDevice').click
    expect(page).to have_content('Your device was successfully set up')
    find('#registerU2FDevice').click
    u2f_device
  end

  describe "registration" do
    let(:user) { create(:user) }
    before { login_as(user) }

    describe 'when 2FA via OTP is disabled' do
      it 'allows registering a new device' do
        visit profile_account_path
        click_on 'Enable Two-factor authentication'
        register_u2f_device
        expect(page.body).to match('Your U2F device was registered')
      end

      it 'allows registering more than one device' do
        visit profile_account_path

        # First device
        click_on 'Enable Two-factor authentication'
        register_u2f_device
        expect(page.body).to match('Your U2F device was registered')

        # Second device
        click_on 'Manage Two-factor Authentication'
        register_u2f_device
        expect(page.body).to match('Your U2F device was registered')

        click_on 'Manage Two-factor Authentication'
        expect(page.body).to match('You have 2 U2F devices registered')
      end
    end

    describe 'when 2FA via OTP is enabled' do
      before { user.update_attributes(otp_required_for_login: true) }

      it 'allows registering a new device' do
        visit profile_account_path
        click_on 'Manage Two-factor Authentication'
        expect(page.body).to match("You've already enabled two-factor authentication using mobile")
        register_u2f_device
        expect(page.body).to match('Your U2F device was registered')
      end

      it 'allows registering more than one device' do
        visit profile_account_path

        # First device
        click_on 'Manage Two-factor Authentication'
        register_u2f_device
        expect(page.body).to match('Your U2F device was registered')

        # Second device
        click_on 'Manage Two-factor Authentication'
        register_u2f_device
        expect(page.body).to match('Your U2F device was registered')

        click_on 'Manage Two-factor Authentication'
        expect(page.body).to match('You have 2 U2F devices registered')
      end
    end

    it 'allows the same device to be registered for multiple users' do
      # First user
      visit profile_account_path
      click_on 'Enable Two-factor authentication'
      u2f_device = register_u2f_device
      expect(page.body).to match('Your U2F device was registered')
      logout

      # Second user
      login_as(:user)
      visit profile_account_path
      click_on 'Enable Two-factor authentication'
      register_u2f_device(u2f_device)
      expect(page.body).to match('Your U2F device was registered')

      expect(U2fRegistration.count).to eq(2)
    end
  end

  describe "authentication" do
    let(:user) { create(:user) }

    before do
      # Register and logout
      login_as(user)
      visit profile_account_path
      click_on 'Enable Two-factor authentication'
      @u2f_device = register_u2f_device
      logout
    end

    describe "when 2FA via OTP is disabled" do
      it "allows logging in with the U2F device" do
        login_with(user)

        @u2f_device.respond_to_u2f_authentication
        find("#loginU2FDevice").click
        expect(page.body).to match('We heard back from your U2F device')
        find("#authenticateU2FDevice").click
        expect(page.body).to match('Signed in successfully')
      end
    end

    describe "when 2FA via OTP is enabled" do
      it "allows logging in with the U2F device" do
        user.update_attributes(otp_required_for_login: true)
        login_with(user)

        @u2f_device.respond_to_u2f_authentication
        find("#loginU2FDevice").click
        expect(page.body).to match('We heard back from your U2F device')
        find("#authenticateU2FDevice").click
        expect(page.body).to match('Signed in successfully')
      end
    end

    describe "when a given U2F device has already been registered by another user" do
      describe "but not the current user" do
        it "does not allow logging in with that particular device" do
          # Register current user with the different U2F device
          current_user = login_as(:user)
          visit profile_account_path
          click_on 'Enable Two-factor authentication'
          register_u2f_device
          logout

          # Try authenticating user with the old U2F device
          login_as(current_user)
          @u2f_device.respond_to_u2f_authentication
          find("#loginU2FDevice").click
          expect(page.body).to match('We heard back from your U2F device')
          find("#authenticateU2FDevice").click
          expect(page.body).to match('Authentication via U2F device failed')
        end
      end

      describe "and also the current user" do
        it "allows logging in with that particular device" do
          # Register current user with the same U2F device
          current_user = login_as(:user)
          visit profile_account_path
          click_on 'Enable Two-factor authentication'
          register_u2f_device(@u2f_device)
          logout

          # Try authenticating user with the same U2F device
          login_as(current_user)
          @u2f_device.respond_to_u2f_authentication
          find("#loginU2FDevice").click
          expect(page.body).to match('We heard back from your U2F device')
          find("#authenticateU2FDevice").click
          expect(page.body).to match('Signed in successfully')
        end
      end
    end

    describe "when a given U2F device has not been registered" do
      it "does not allow logging in with that particular device" do
        unregistered_device = FakeU2fDevice.new(page)
        login_as(user)
        unregistered_device.respond_to_u2f_authentication
        find("#loginU2FDevice").click
        expect(page.body).to match('We heard back from your U2F device')
        find("#authenticateU2FDevice").click
        expect(page.body).to match('Authentication via U2F device failed')
      end
    end
  end

  describe "when two-factor authentication is disabled" do
    let(:user) { create(:user) }

    before do
      login_as(user)
      visit profile_account_path
      click_on 'Enable Two-factor authentication'
      register_u2f_device
    end

    it "deletes u2f registrations" do
      expect { click_on "Disable" }.to change { U2fRegistration.count }.from(1).to(0)
    end
  end
end
