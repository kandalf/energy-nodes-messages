require 'eventmachine'
require 'json'
require_relative 'messenger'

class Device
  attr_reader :energy_level

  include Messenger

  ENERGY_ALERT_LEVEL = 200
  ENERGY_FULL_LEVEL  = 1000

  def initialize
    connection.start
    @channel     = connection.create_channel
    @exchange    = @channel.topic("energy_requests")
    @nrg_xchange = @channel.topic("energy_delivery")
    @queue = @channel.queue("", :exclusive => true)
    @energy_level = ENERGY_FULL_LEVEL
    @recharging = false
  end

  def request_energy
    @message = { :device_id => id }
    @exchange.publish(@message.to_json)
  end

  def needs_energy?
    if @energy_level < ENERGY_ALERT_LEVEL
      @recharging = true
    end

    @recharging && (@energy_level < ENERGY_FULL_LEVEL)
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
        timer = EventMachine::PeriodicTimer.new(1) do
          energy_consuming_task

          request_energy if needs_energy?
        end

        @queue.subscribe(:lock => true) do |info, properties, body|
          amount = body.to_i
          store_energy(amount)
        end
      end
    rescue Interrupt => _
      timer.cancel
      @channel.close
      connection.close
    end
  end

  def energy_consuming_task
    log "[#{id}] Discharging... #{@energy_level * 100 / ENERGY_FULL_LEVEL}%" unless @recharging
    @energy_level -= rand(40..85)
    raise "Out Of Energy" if @energy_level <= 0
  end

  private
  def store_energy(amount)
    @energy_level += amount
    log "Charging... #{@energy_level * 100 / ENERGY_FULL_LEVEL}%"

    if @energy_level > ENERGY_FULL_LEVEL
      @energy_level = ENERGY_FULL_LEVEL
      @recharging = false
      log "Charged!"
    end
  end
end
