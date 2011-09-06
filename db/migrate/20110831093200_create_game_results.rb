class CreateGameResults < ActiveRecord::Migration
  def change
    create_table :game_results, :id => false do |t|
      t.integer :comment_id
      t.integer :correct_guess_count, :default => 0
      t.integer :wrong_guess_count, :default => 0
    end
  end
end