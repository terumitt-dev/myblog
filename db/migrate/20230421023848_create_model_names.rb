class CreateModelNames < ActiveRecord::Migration[7.0]
  def change
    create_table :model_names do |t|

      t.timestamps
    end
  end
end
