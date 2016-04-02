require 'json'
require_relative 'messenger'
require_relative 'fake_mutex'

class EnergyNode
  include Messenger

  def initialize
    connection.start
    @channel      = connection.create_channel
    @requests_xch = @channel.topic("energy_requests")
    @delivery_xch = @channel.topic("energy_delivery")
    @queue        = @channel.queue("", :exclusive => true)
  end

  def run
    @queue.bind(@requests_xch)
    log "Energy Node #{id} running. Press Ctrl+C to exit"

    begin
      @queue.subscribe(:block => true) do |info, properties, body|
        msg = JSON.parse(body)

        #Claim device in need if it's not locked by other node
        unless FakeMutex.locked?(msg["device_id"])
          FakeMutex.lock(msg["device_id"]) {
            log "Delivering energy from node #{id} to #{msg["device_id"]}"

            deliver_energy_to(msg["device_id"])
          }
        end
      end
    rescue Interrupt => _
      @channel.close
      connection.close
    end
  end
end

def deliver_energy_to(device_id)
  # Use an exchange to «deliver energy» to the device with the ID `id`
  amount = rand(150..200)
  @delivery_xch.publish(amount.to_s, :routing_key => device_id)
end
