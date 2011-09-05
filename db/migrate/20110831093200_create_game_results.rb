# $proportion = $_SESSION['correct'] - $_SESSION['wrong'];
# if ($proportion <= -2) { echo "People tend to guess the wrong source for this comment."; }
# elseif ($proportion >= 2) {echo "People tend to guess this comment correctly."; }
# elseif ($proportion == 0) {echo "This comment attracts even numbers of correct and wrong guesses.";
# else "" }


class CreateGameResults < ActiveRecord::Migration
  def change
    create_table :game_results, :id => false do |t|
      t.integer :comment_id
      t.integer :correct_guess_count, :default => 0
      t.integer :wrong_guess_count, :default => 0
    end
  end
end