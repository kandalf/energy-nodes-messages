require_relative 'lib/messenger'

class Device
  include Messenger

  def initialize
    connection.start
    @channel = connection.create_channel
    @exchange = @channel.topic("energy_requests")
  end

  def request_energy
    @message = { :node_id => id, :message => :need_energy }
    @exchange.publish(@message.to_s)
  end
end
