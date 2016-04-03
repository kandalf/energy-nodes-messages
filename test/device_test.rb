require File.expand_path(__FILE__).concat("/../test_helper")

#Monkey patch to make channels accessible so
#we can ensure exchanges are created properly
#on construction.
class Bunny::Session
  attr_reader :channels
end

#Monkey patches to avoid repetitive excecutions of EventMachine
#but keeping the blocks functionalities passed to its methods
module EventMachine
  def self.run
    yield if block_given?
  end
end

class EventMachine::PeriodicTimer
  def initialize(args)
    yield if block_given?
  end
end


describe "Device" do
  before do
    @dev = Device.new
    @dev.stubs(:log).returns(true) #Supress unnecessary output
  end

  it "should setup exchanges" do
    xchg_names = @dev.connection.channels[1].exchanges.keys

    assert xchg_names.include?("energy_requests")
    assert xchg_names.include?("energy_delivery")
  end

  it "should start full" do
    assert !@dev.needs_energy?
    assert_equal Device::ENERGY_FULL_LEVEL, @dev.energy_level
  end

  it "should need energy when alert level is reached" do
    @dev.energy_consuming_task while(@dev.energy_level > Device::ENERGY_ALERT_LEVEL) 
    assert @dev.needs_energy?
  end

  it "should request energy when necessary" do
    Bunny::Queue.any_instance.stubs(:subscribe).returns(true)
    @dev.stubs(:needs_energy?).returns(true)
    @dev.expects(:request_energy)

    @dev.run
  end
end
