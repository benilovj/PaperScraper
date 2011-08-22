require 'spec_helper'
require 'game'

describe Question do
  it { Question.new(1, nil).should_not be_answered }

  it "should be completed as soon as it gets an answer" do
    question = Question.new(1, nil)
    question.answer = "some answer"
    question.should be_answered
  end

  it "should return the text of the comment" do
    Question.new(1, mock(Comment, :comment => "xyz")).comment_text.should == "xyz"
  end
  
  it "should return the question number" do
    Question.new(3, nil).number.should == 3
  end
end

describe Game do
  before(:each) do
    @papers = {:guardian => mock(Paper, :name => "Guardian"),
               :mail     => mock(Paper, :name => "Daily Mail")}
    @comment_source = mock(RandomCommentSource, :new_comment => mock(Comment, :comment => "Comment from DB"))
    RandomCommentSource.stub!(:new).and_return(@comment_source)
  end

  def game_with_mail_and_guardian
    Game.new(@papers[:guardian], @papers[:mail])
  end

  def mail; @papers[:mail]; end
  def guardian; @papers[:guardian]; end
  
  context "initially" do
    let(:game) {game_with_mail_and_guardian}

    it { game.should_not be_finished }

    it "should provide the names of the choices" do
      game.choice_names.should == ["Guardian", "Daily Mail"]
    end

    it "should fetch the text of the first comment" do
      game.current_question.comment_text.should == "Comment from DB"
    end

    it "should hit the DB exactly once per comment" do
      a_paper = mock(Paper, :name => "Mail")
      game = Game.new(a_paper, a_paper)
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
      @game.answer = "Daily Mail"
    end

    it "should be on the second comment" do
      @game.current_question.number.should == 2
    end
  end

  context "after 10 questions and 9 answers" do
    before do
      @game = game_with_mail_and_guardian
      
      9.times { @game.answer = "Guardian" }
      @game.current_question.comment_text
    end
    
    it { @game.should_not be_finished }
  end

  context "after 10 answers" do
    before do
      @game = game_with_mail_and_guardian

      10.times { @game.answer = "Guardian" }
    end

    it { @game.should be_finished }
  end
end