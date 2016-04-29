require 'spec_helper'

feature 'U2F Devices', feature: true, js: true do
  include U2fDeviceHelper

  def register_u2f_device
    respond_to_u2f_registration
    find('#setupU2FDevice').click
    expect(page).to have_content('Your device was successfully set up')
    find('#registerU2FDevice').click
  end

  describe 'when 2FA via OTP is disabled' do
    before { login_as(:user) }

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
    before do
      user = login_as(:user)
      user.update_attributes(otp_required_for_login: true)
    end

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
end
