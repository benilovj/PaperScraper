class Question
  attr_writer :answer
  attr_reader :number
  
  def initialize(number, comment)
    @comment = comment
    @number = number
  end
  
  def answered?
    not @answer.nil?
  end
  
  def comment_text
    @comment.comment
  end
end

class Game
  def initialize
    @questions = []
  end
  
  def finished?
    @questions.select(&:answered?).size == 10
  end
  
  def answer=(guess)
    current_question.answer = guess
  end
  
  def valid_choice?(choice)
    ["guardian", "mail"].include?(choice.downcase)
  end
  
  def current_question
    fetch_new_comment if @questions.all?(&:answered?)
    @questions.last
  end
  
  protected
  def fetch_new_comment
    @questions << Question.new(@questions.size + 1, Comment.random)
  end
end