class QuizQuestion
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
  
  def reaction
    (answer_correct? ? PositiveReaction : NegativeReaction).new(@comment)
  end
  
  def dump
    [@comment.id, answered? ? @answer.name : nil]
  end
  
  protected
  def answer_correct?
    @comment.paper == @answer
  end
end

class Reaction
  def initialize(comment, exclamations)
    @comment = comment
    @exclamations = exclamations
  end
  
  def exclamation
    @exclamation ||= @exclamations.sample
  end
  
  def correct_paper_name
    @comment.paper.name
  end
  
  def correct_paper_logo
    @comment.paper.logo
  end
  
  def source_article_url
    @comment.article.url
  end
end

class PositiveReaction < Reaction
  EXCLAMATIONS = ["Super!", "Great!", "Well done!", "Good!", "Excellent!", "Good guess!", "You're good!", "Incredible!", "You're right!"]
  def initialize(comment)
    super(comment, EXCLAMATIONS)
  end
end

class NegativeReaction < Reaction
  EXCLAMATIONS = ["Hard luck!", "Oh dear", "Incorrect guess", "You're wrong", "Pity", "Nope", "Oh no!", "Hard cheese", "Sorry old thing"]
  def initialize(comment)
    super(comment, EXCLAMATIONS)
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
  def initialize(papers, questions = [])
    @papers = papers
    @questions = questions
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
  
  def reaction
    @questions.last.reaction
  end
  
  def current_question
    fetch_and_save_new_comment if @questions.all?(&:answered?)
    @questions.last
  end
  
  def dump
    {:papers => choice_names, :questions => @questions.collect(&:dump)}
  end

  class << self
    def load(dumped_form)
      papers = dumped_form[:papers].collect {|paper_name| PAPERS[paper_name]}
      question_ids = dumped_form[:questions].collect(&:first)
      comments_from_db = Comment.find(:all, :conditions => "id in (#{question_ids.join(", ")})")
      qns = question_ids.each_with_index.map {|qn_id, i| QuizQuestion.new(i + 1, comments_from_db.detect {|c| c.id == qn_id})}
      qns.zip(dumped_form[:questions].collect(&:last)).each {|qn, answer_name| qn.answer = PAPERS[answer_name] }
      new(papers, qns)
    end
  end
  
  protected
  def fetch_and_save_new_comment
    @questions << QuizQuestion.new(@questions.size + 1, fetch_new_comment)
  end
  
  def fetch_new_comment
    RandomCommentSource.new(@papers).new_comment
  end
end