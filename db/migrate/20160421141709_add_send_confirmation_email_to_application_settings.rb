class AddSendConfirmationEmailToApplicationSettings < ActiveRecord::Migration
  def up
    add_column :application_settings, :send_user_confirmation_email, :boolean, default: false

    #Sets confirmation email to true by default on existing installations.
    ApplicationSetting.update_all(send_user_confirmation_email: true)
  end

  def down
    remove_column :application_settings, :send_user_confirmation_email
  end
end
