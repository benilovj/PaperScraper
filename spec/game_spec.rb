require 'spec_helper'
require 'game'

module GameHelpers
  def papers
    @papers ||= {:guardian => mock(Paper, :name => "Guardian"),
                 :mail     => mock(Paper, :name => "Daily Mail")}
  end
  
  def game_with_mail_and_guardian
    Game.new([guardian, mail])
  end

  def mail; papers[:mail]; end
  def guardian; papers[:guardian]; end
  
  def mail_comment
    mock(Comment, :comment => "Comment from DB", :paper => mail, :id => 123)
  end
end

describe QuizQuestion do
  include GameHelpers
  
  context "unanswered" do
    specify { QuizQuestion.new(1, nil).should_not be_answered }
    before do
      GameResult.stub!(:correctly_guessed)
    end

    it "should be completed as soon as it gets an answer" do
      question = QuizQuestion.new(1, mail_comment)
      question.answer = mail
      question.should be_answered
    end

    it "should return the text of the comment" do
      QuizQuestion.new(1, mock(Comment, :comment => "xyz")).comment_text.should == "xyz"
    end
  
    it "should return the question number" do
      QuizQuestion.new(3, nil).number.should == 3
    end
    
    it "should serialize" do
      qn = QuizQuestion.new(1, mail_comment)
      qn.dump.should == [123, nil]
      qn.answer = mail
      qn.dump.should == [123, "Daily Mail"]
    end
  end
  
  context "correctly answered" do
    def paper; @paper ||= mock(Paper); end    
    before do
      @qn = QuizQuestion.new(1, comment = mock(Comment, :paper => paper))
      GameResult.should_receive(:correctly_guessed).with(comment)
      @qn.answer = paper
    end
    
    it "should provoke a positive reaction" do
      @qn.reaction.should be_a(PositiveReaction)
    end
    
    it "should contribute to the score" do
      @qn.score.should == 1
    end
  end
  
  context "incorrectly answered" do
    before do
      @qn = QuizQuestion.new(1, comment = mock(Comment, :paper => mock("a paper")))
      GameResult.should_receive(:wrongly_guessed).with(comment)
      @qn.answer = mock("another paper")
    end
    
    it "should provoke a negative reaction" do
      @qn.reaction.should be_a(NegativeReaction)
    end
    
    it "should not contribute to the score" do
      @qn.score.should == 0
    end
  end
  
  context "instantiated with an answer" do
    subject { QuizQuestion.new(1, mail_comment, mail) }
    
    it { should be_answered }
    specify { subject.reaction.should be_a(PositiveReaction) }
  end
end

shared_examples "a reaction" do
  let(:reaction) do
    paper = mock(Paper, :name => "correct paper", :logo => "http://paper.com/logo.jpg")
    article = mock(Article, :url => "http://xxx")
    comment = mock(Comment, :paper => paper, :article => article)
    described_class.new(comment)
  end
  
  specify { reaction.correct_paper_name.should eq("correct paper") }
  specify { reaction.correct_paper_logo.should eq("http://paper.com/logo.jpg") }
  
  it "should provide a url to the source article" do
    reaction.source_article_url.should eq("http://xxx")
  end
end

describe PositiveReaction do
  it_behaves_like "a reaction"
  
  let(:reaction) do
    paper = mock(Paper, :name => "correct paper")
    comment = mock(Comment, :paper => paper)
    PositiveReaction.new(comment)
  end
  
  it "should provide an exclamation" do
    reaction.exclamation.should be_included_in(PositiveReaction::EXCLAMATIONS)
  end
end

describe NegativeReaction do
  it_behaves_like "a reaction"
  
  let(:reaction) do
    paper = mock(Paper, :name => "correct paper")
    comment = mock(Comment, :paper => paper)
    NegativeReaction.new(comment)
  end
  
  it "should be positive" do
    reaction.exclamation.should be_included_in(NegativeReaction::EXCLAMATIONS)
  end
end

describe Game do
  include GameHelpers
  before(:each) do
    GameResult.stub!(:correctly_guessed)
    GameResult.stub!(:wrongly_guessed)
    @comment_source = mock(RandomCommentSource, :new_comment => mail_comment)
    RandomCommentSource.stub!(:new).and_return(@comment_source)
  end
  
  context "initially" do
    let(:game) {game_with_mail_and_guardian}

    specify { game.should_not be_finished }

    it "should provide the names of the choices" do
      game.choice_names.should == ["Guardian", "Daily Mail"]
    end

    it "should fetch the text of the first comment" do
      game.current_question.comment_text.should == "Comment from DB"
    end

    it "should hit the DB exactly once per comment" do
      a_paper = mock(Paper, :name => "Mail")
      game = Game.new([a_paper, a_paper])
      @comment_source.should_receive(:new_comment).exactly(:once).and_return(mock(Comment, :comment => "Comment from DB"))
      2.times { game.current_question.comment_text.should == "Comment from DB"}
    end

    it "should provide the comment number" do
      game.current_question.number.should == 1
    end
    
    it "should provide the list of possible answers" do
      game.should be_a_valid_choice(guardian)
      game.should be_a_valid_choice(mail)

      game.should_not be_a_valid_choice(mock(Paper, :name => "Independent"))
    end
  end

  context "after one answer" do
    before do
      @game = game_with_mail_and_guardian
      @game.answer = mail
    end

    it "should be on the second comment" do
      @game.current_question.number.should == 2
    end

    specify { @game.reaction.should be_a(Reaction) }
    specify "dump should work" do
      @game.dump.should == {:papers => ["Guardian", "Daily Mail"],
                            :questions => [[123, "Daily Mail"]]}
    end
  end

  context "after 10 questions and 9 answers" do
    before do
      @game = game_with_mail_and_guardian
      9.times { @game.answer = guardian }
      @game.current_question.comment_text
    end
    
    specify { @game.should_not be_finished }
    it "should reconstitute a dumped game" do
      search_condition = 'id in (%s)' % ([123]*10).join(", ")
      Comment.should_receive(:find).with(:all, :conditions => search_condition).and_return([mock(Comment, :id => 123,
                                                                                                          :name => "Guardian",
                                                                                                          :paper => PAPERS[:guardian])])
      Game.load(@game.dump).dump.should == @game.dump
    end
  end

  context "after 10 incorrect answers" do
    before do
      @game = game_with_mail_and_guardian
      10.times { @game.answer = guardian }
    end

    specify { @game.should be_finished }
    specify { @game.score.should == 0}
  end
end
