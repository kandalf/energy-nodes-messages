require_relative 'messenger'

class EnergyNode
  include Messenger

  def initialize
    connection.start
    @channel  = connection.create_channel
    @exchange = @channel.topic("energy_requests")
    @queue    = @channel.queue("", :exclusive => true)
  end

  def run
    @queue.bind(@exchange)

    puts "[#{Time.now.utc.to_s}] Energy Node #{id} running. Press Ctrl+C to exit"

    begin
      @queue.subscribe(:block => true) do |info, properties, body|
        puts "[*] Receiving #{body.inspect}"
        puts "[INFO] #{info.inspect}"
        puts "[PROPS] #{properties.inspect}"
      end
    rescue Interrupt => _
      @channel.close
      @connection.close
    end
  end
end
