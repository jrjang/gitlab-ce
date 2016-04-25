class CreateU2fRegistrations < ActiveRecord::Migration
  def change
    create_table :u2f_registrations do |t|
      t.text :certificate
      t.string :key_handle
      t.string :public_key
      t.integer :counter
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end