class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments, :force => true do |t|
      t.text :comment
      t.text :url
      t.text :paper
      t.timestamps
    end
  end

  def self.down
    drop_table :comments
  end
end