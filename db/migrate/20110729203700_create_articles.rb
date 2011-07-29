class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.text :url
      t.text :paper
      t.boolean :consumed, :default => 0
      t.timestamps
    end
  end
end