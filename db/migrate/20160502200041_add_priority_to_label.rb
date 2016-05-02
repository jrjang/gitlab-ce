class AddPriorityToLabel < ActiveRecord::Migration
  def change
    add_column :labels, :priority, :boolean, default: false
  end
end
