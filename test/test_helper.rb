require 'minitest/autorun'
require 'minitest/spec'
require 'mocha/test_unit'

Dir["./lib/**/*.rb"].each{ |file| require file }
