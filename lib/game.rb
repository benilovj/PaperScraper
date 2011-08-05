class CommentAndAnswerPair
  def initialize(comment)
    @comment = comment
  end
  
  def completed?
    not @answer.nil?
  end
  
  def answer=(answer)
    @answer = answer
  end
  
  def comment_text
    @comment.comment
  end
end

class Game
  def initialize
    @comments_answers = []
  end
  
  def text_of_comment_to_be_guessed
    comment_to_be_guessed.comment_text
  end
  
  def comment_number
    comment_to_be_guessed
    @comments_answers.size
  end
  
  def finished?
    @comments_answers.size >= 10
  end
  
  def answer=(guess)
    comment_to_be_guessed.answer = guess
  end
  
  protected
  def comment_to_be_guessed    
    @comments_answers << CommentAndAnswerPair.new(Comment.random) if @comments_answers.all?(&:completed?)
    @comments_answers.last
  end
end