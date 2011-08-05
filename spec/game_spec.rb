require 'spec_helper'
require 'game'

describe CommentAndAnswerPair do
  it { CommentAndAnswerPair.new(nil).should_not be_completed }
  
  it "should be completed as soon as it gets an answer" do
    pair = CommentAndAnswerPair.new(nil)
    pair.answer = "some answer"
    pair.should be_completed
  end
  
  it "should return the text of the comment" do
    CommentAndAnswerPair.new(mock(Comment, :comment => "xyz")).comment_text.should == "xyz"
  end
end

describe Game do
  context "initially" do
    let(:game) {Game.new}
  
    it { should_not be_finished }
  
    it "should give the first comment" do
      Comment.should_receive(:random).and_return(mock(Comment, :comment => "Comment from DB"))    
      game.text_of_comment_to_be_guessed.should == "Comment from DB"
    end
    
    it "should hit the DB exactly once per comment" do
      Comment.should_receive(:random).exactly(:once).and_return(mock(Comment, :comment => "Comment from DB"))    
      2.times { game.text_of_comment_to_be_guessed.should == "Comment from DB"}
    end
    
    it "should be on the first comment" do
      game.comment_number.should == 1
    end
  end
  
  context "after one answer" do
    before do
      @game = Game.new
      @game.answer = "Mail"
    end
    
    it "should be on the second comment" do
      @game.comment_number.should == 2
    end
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