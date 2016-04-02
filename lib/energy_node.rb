require 'json'
require_relative 'messenger'
require_relative 'fake_mutex'

class EnergyNode
  include Messenger

  ENERGY_CHUNK = 200

  def initialize
    connection.start
    @channel      = connection.create_channel
    @requests_xch = @channel.topic("energy_requests")
    @delivery_xch = @channel.topic("energy_delivery")
    @queue        = @channel.queue("", :exclusive => true)
  end

  def run
    @queue.bind(@requests_xch)

    puts "[#{Time.now.utc.to_s}] Energy Node #{id} running. Press Ctrl+C to exit"

    begin
      @queue.subscribe(:block => true) do |info, properties, body|
        msg = JSON.parse(body)

        unless FakeMutex.locked?(msg["node_id"])
          FakeMutex.lock(msg["node_id"]) {
            puts "[#{Time.now.utc.to_s}] Delivering energy from node #{id} to #{msg["node_id"]}"

            deliver_energy_to(msg["node_id"])
          }
        end
      end
    rescue Interrupt => _
      @channel.close
      connection.close
    end
  end
end

def deliver_energy_to(id)
  @delivery_xch.publish("200", :routing_key => id)
end
