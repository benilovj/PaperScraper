class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments, :force => true do |t|
      t.text :comment
      t.text :url
      t.text :paper
      t.timestamps
    end
  end
end