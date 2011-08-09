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
  context "initially" do
    let(:game) {Game.new}

    it { should_not be_finished }

    it "should fetch the text of the first comment" do
      Comment.should_receive(:random).and_return(mock(Comment, :comment => "Comment from DB"))
      game.current_question.comment_text.should == "Comment from DB"
    end

    it "should hit the DB exactly once per comment" do
      Comment.should_receive(:random).exactly(:once).and_return(mock(Comment, :comment => "Comment from DB"))
      2.times { game.current_question.comment_text.should == "Comment from DB"}
    end

    it "should provide the comment number" do
      game.current_question.number.should == 1
    end
    
    it "should provide the list of possible answers" do
      game.should be_a_valid_choice("guardian")
      game.should be_a_valid_choice("Guardian")
      game.should be_a_valid_choice("Mail")
      game.should be_a_valid_choice("mail")

      game.should_not be_a_valid_choice("independent")
    end
  end

  context "after one answer" do
    before do
      @game = Game.new
      @game.answer = "Mail"
    end

    it "should be on the second comment" do
      @game.current_question.number.should == 2
    end
  end

  context "after 10 questions and 9 answers" do
    before do
      @game = Game.new
      Comment.stub!(:random).times.and_return(mock(Comment, :comment => "Comment from DB"))
      
      9.times { @game.answer = "Guardian" }
      @game.current_question.comment_text
    end
    
    it { @game.should_not be_finished }
  end

  context "after 10 answers" do
    before do
      @game = Game.new
      Comment.should_receive(:random).exactly(10).times.and_return(mock(Comment, :comment => "Comment from DB"))

      10.times { @game.answer = "Guardian" }
    end

    it { @game.should be_finished }
  end
end