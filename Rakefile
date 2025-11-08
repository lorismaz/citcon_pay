# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc 'Run console with CitconPay loaded'
task :console do
  require 'irb'
  require_relative 'lib/citcon_pay'

  # Load configuration from environment if available
  if ENV['CITCON_API_KEY']
    CitconPay.configure do |config|
      config.api_key = ENV['CITCON_API_KEY']
      config.environment = ENV.fetch('CITCON_ENV', 'sandbox').to_sym
    end
    puts 'CitconPay configured with environment API key'
  else
    puts 'Set CITCON_API_KEY environment variable to configure the client'
  end

  ARGV.clear
  IRB.start
end

desc 'Run example scripts'
namespace :examples do
  desc 'Run charge creation example'
  task :charge do
    ruby 'examples/create_charge.rb'
  end

  desc 'Run WeChat Pay example'
  task :wechat do
    ruby 'examples/create_wechat_charge.rb'
  end

  desc 'Run transaction query example'
  task :query do
    ruby 'examples/query_transaction.rb'
  end

  desc 'Run refund example'
  task :refund do
    ruby 'examples/process_refund.rb'
  end
end
