require 'eventmachine'
require 'json'
require_relative 'messenger'

class Device
  include Messenger

  def initialize
    connection.start
    @channel     = connection.create_channel
    @exchange    = @channel.topic("energy_requests")
    @nrg_xchange = @channel.topic("energy_delivery")
    @queue = @channel.queue("", :exclusive => true)
  end

  def request_energy
    @message = { :node_id => id, :message => :need_energy }
    @exchange.publish(@message.to_json)
  end

  def run
    #EventMachine cannot be stopped in the rescue block since it will
    #raise a context error
    Signal.trap("TERM"){ EventMachine.stop }
    Signal.trap("INT"){ EventMachine.stop }
    @queue.bind(@nrg_xchange, :routing_key => id)

    begin
      EventMachine.run do
        #Request energy every 5 seconds
        @timer = EventMachine::PeriodicTimer.new(5) do
          request_energy
        end

        @queue.subscribe(:lock => true) do |info, properties, body|
          log "Receiving #{body}"
        end
      end
    rescue Interrupt => _
      @timer.cancel
      @channel.close
      connection.close
    end
  end
end
