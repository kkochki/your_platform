class CreateDecisionMakingOptions < ActiveRecord::Migration
  def change
    create_table :decision_making_options do |t|
      t.string :title
      t.text :description
      t.integer :process_id

      t.timestamps null: false
    end
  end
end
