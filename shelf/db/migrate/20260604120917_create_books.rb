class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :title
      t.string :author
      t.text :description
      t.integer :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
