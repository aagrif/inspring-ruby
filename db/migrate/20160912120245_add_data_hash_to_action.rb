class AddDataHashToAction < ActiveRecord::Migration[5.0]
  def change
    add_column :actions, :data, :text
    add_column :subscribers, :data, :text
  end
end
