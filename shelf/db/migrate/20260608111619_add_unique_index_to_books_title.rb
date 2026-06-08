class AddUniqueIndexToBooksTitle < ActiveRecord::Migration[8.1]
  def change
    add_index :books, :title, unique: true
  end
end
