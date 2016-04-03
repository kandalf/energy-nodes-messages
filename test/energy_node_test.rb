require File.expand_path(__FILE__).concat("/../test_helper")

#Monkey patch to avoid actual subscription and keeping
#the behavior of the block passed within the code
class Bunny::Queue
  def subscribe(args = {})
    yield if block_given?
  end
end

describe "EnergyNode" do
  before do
    @node = EnergyNode.new
    @node.stubs(:log) #Supress unnecessary output
  end

  after do
    JSON.unstub(:parse)
    FakeMutex.unstub(:locked?)
  end

  it "should setup exchanges" do
    xchg_names = @node.connection.channels[1].exchanges.keys

    assert xchg_names.include?("energy_requests")
    assert xchg_names.include?("energy_delivery")
  end

  it "should deliver if device is not locked by other node" do
    JSON.expects(:parse).returns({ "device_id" => "fake-id" })
    assert !FakeMutex.locked?("fake_id")

    @node.expects(:deliver_energy_to).with("fake-id").once

    @node.run
  end

  it "should not deliver if device is locked by other node" do
    JSON.expects(:parse).returns({ "device_id" => "fake-id" })
    FakeMutex.stubs(:locked?).with("fake-id").returns(true)

    @node.expects(:deliver_energy_to).with("fake-id").never

    @node.run
  end
end
