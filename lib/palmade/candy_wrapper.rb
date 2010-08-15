CANDY_WRAPPER_LIB_DIR = File.expand_path(File.dirname(__FILE__)) unless defined?(CANDY_WRAPPER_LIB_DIR)
CANDY_WRAPPER_ROOT_DIR = File.expand_path(File.join(CANDY_WRAPPER_LIB_DIR, '../..')) unless defined?(CANDY_WRAPPER_ROOT_DIR)

require 'rubygems'
require 'logger'

module Palmade
  module CandyWrapper
    def self.logger=(l); @logger = l; end
    def self.logger; @logger ||= Logger.new(STDOUT); end

    autoload :Twitow, File.join(CANDY_WRAPPER_LIB_DIR, 'candy_wrapper/twitow')
    autoload :Posporo, File.join(CANDY_WRAPPER_LIB_DIR, 'candy_wrapper/posporo')
  end
end
