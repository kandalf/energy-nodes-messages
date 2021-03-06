# Simple mutex functionality to grant single delivery to devices
#
module FakeMutex
  @register = []

  def self.lock(id, &blk)
    @register << id

    if block_given?
      yield
      sleep 0.3 #add minimum delay to grant lock
      self.free(id)
    end
  end

  def self.locked?(id)
    @register.include?(id)
  end

  def self.free(id)
    @register.delete(id)
  end
end
