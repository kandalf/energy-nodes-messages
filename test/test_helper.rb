require 'minitest/autorun'
require 'minitest/spec'
require 'mocha/test_unit'

Dir["./lib/**/*.rb"].each{ |file| require file }

#Monkey patch to make channels accessible so
#we can ensure exchanges are created properly
#on construction.
class Bunny::Session
  attr_reader :channels
end
