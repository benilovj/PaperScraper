class QuizQuestion
  attr_reader :number
  
  def initialize(number, comment, answer = nil)
    @comment = comment
    @number = number
    @answer = answer
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
  
  def score
    answer_correct? ? 1 : 0
  end

  def answer=(answer)
    @answer = answer
    if answer_correct?
      GameResult.correctly_guessed(@comment)
    else
      GameResult.wrongly_guessed(@comment)
    end
  end
  
	def answer=(answer)
    @answer = answer
    if answer_correct?
      GameResult.correctly_guessed(@comment)
    else
      GameResult.wrongly_guessed(@comment)
    end
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
  
  def comment_on_stats
    case GameResult.stats_for(@comment)
    when :inconclusive then ""
    when :mostly_correct then "People tend to guess this comment correctly."
    when :mostly_wrong then "People tend to guess the wrong source for this comment."
    when :equal_number_of_correct_wrong then "This comment attracts even numbers of correct and wrong guesses."
    else nil
    end
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

class GameBuilder
  def initialize
    @questions = []
  end
  
  def with_papers_named(paper_names)
    @paper_names = paper_names
    self
  end
  
  def with_question(comment_id, answer)
    @questions << [comment_id, answer]
    self
  end
  
  def build
    papers = PAPERS.with_names(@paper_names)
    qns = build_questions
    Game.new(papers, qns)
  end
  
  protected
  def build_questions
    question_ids.each_with_index.map {|comment_id, i| QuizQuestion.new(i + 1, comment_with(comment_id), answer_to_qn(i))}
  end
  
  def comment_with(comment_id)
    comments_from_db.detect {|c| c.id == comment_id}
  end
  
  def comments_from_db
    @comments_from_db ||= Comment.find(:all, :conditions => "id in (#{question_ids.join(", ")})")
  end
  
  def question_ids
    @questions.map(&:first)
  end
  
  def answer_to_qn(index)
    PAPERS[@questions[index].last]
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

  def score
    @questions.map(&:score).inject(:+)
  end

  class << self
    def load(dumped_form)
      builder = GameBuilder.new.with_papers_named(dumped_form[:papers])
      dumped_form[:questions].each {|comment_id, answer| builder.with_question(comment_id, answer)}
      builder.build
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
