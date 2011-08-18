class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments, :force => true do |t|
      t.integer :article_id
      t.text :comment
      t.text :url
      t.timestamps
    end
  end
end