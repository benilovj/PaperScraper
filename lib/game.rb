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

class RandomCommentSource
  def initialize(papers)
    @papers = papers
  end
  
  def new_comment
    randomly_chosen_paper.random_comment
  end
  
  protected
  def randomly_chosen_paper
    @papers.sample
  end
end

class Game
  def initialize(*papers)
    @papers = papers
    @comment_source = RandomCommentSource.new(papers)
    @questions = []
  end
  
  def choice_names
    @papers.map(&:name)
  end
  
  def finished?
    @questions.select(&:answered?).size == 10
  end
  
  def answer=(guess)
    current_question.answer = guess
  end
  
  def valid_choice?(paper)
    @papers.include?(paper)
  end
  
  def current_question
    fetch_new_comment if @questions.all?(&:answered?)
    @questions.last
  end
  
  protected
  def fetch_new_comment
    @questions << Question.new(@questions.size + 1, @comment_source.new_comment)
  end
end