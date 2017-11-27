class CreatePatrons < ActiveRecord::Migration
  def change
    create_table :patrons do |t|
      t.string :name
      t.string :institution_name
      t.integer :institution_id

      t.timestamps null: false
    end
  end
end
