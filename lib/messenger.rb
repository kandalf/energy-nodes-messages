require 'bunny'
require 'securerandom'

module Messenger
  def id
    @id ||= SecureRandom.hex(4)
  end

  def connection
    @connection ||= Bunny.new
  end

  def log(message)
    puts "[#{Time.now.utc.to_s}] #{message}"
  end
end
