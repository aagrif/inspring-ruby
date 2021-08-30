class AddRecurringScheduleToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :recurring_schedule, :text
  end
end
