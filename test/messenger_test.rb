require File.expand_path(__FILE__).concat("/../test_helper")

class DummyMessenger
  include Messenger
end

describe "Messenger" do
  it "should create connection only once" do
    #Makes Bunny#new to return some value so it's not nil and expects it
    #to be called only once so it ensures Messenger module
    #reuses the connection instead of creating many of them
    Bunny.expects(:new).returns(Bunny::Session.new).once

    messenger = DummyMessenger.new
    messenger.connection
    messenger.connection

    Bunny.unstub(:new)
  end

  it "should auto generate an ID and keep it consistent" do
    messenger = DummyMessenger.new

    generated_id = messenger.id
    assert_equal generated_id, messenger.id #Tests id doesn't get regenerated
  end
end
