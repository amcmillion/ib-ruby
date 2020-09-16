#!/usr/bin/env ruby
#
# This script uses the IB::Gateway to connect to the tws
# 
# It displays all contracts in all accounts
#
# It is assumed, that the TWS/Gateway is running on localhost,  using 7497/4002 as port
#
# call   `ruby list_positions TWS ` to connect to a running TWS-Instance

require 'bundler/setup'
require 'yaml'
require 'ib-gateway'
require 'logger'
require 'ib/db'
require 'indicators/sma'

logger = Logger.new STDOUT
logger.level = Logger::INFO

client_id = ARGV[1] || 2500
specified_port = ARGV[0] || 'Gateway'
port = case specified_port
       when Integer
         specified_port # just use the number
       when /^[gG]/
         4002
       when /^[Tt]/
         7496
       end
ARGV.clear

begin
  G = IB::Gateway.new(get_account_data: true,
                      client_id: client_id,
                      port: port,
                      logger: logger
  )
rescue IB::TransmissionError => e
  puts "E: #{e.inspect}"
end

puts "List of Contracts"
puts '-' * 25
# TODO: An initial accessing of G's properties is needed before we can pull active accounts
# puts	G.all_contracts.map(&:to_human).join("\n")
puts '-' * 25

bad_contracts = []

G.active_accounts.each do |user|
  portfolio_values = user.portfolio_values

  long_stocks = portfolio_values.select { |v| v.stock? && v.long? }
  short_stocks = portfolio_values.select { |v| v.stock? && v.short? }
  long_options = portfolio_values.select { |v| v.option? && v.long? }
  short_options = portfolio_values.select { |v| v.option? && v.short? }


  long_stock_cost_basis = long_stocks.map(&:market_value).inject(0, &:+)
  short_stock_cost_basis = short_stocks.map(&:market_value).inject(0, &:+)

  long_option_cost_basis = long_options.map(&:market_value).inject(0, &:+)
  short_option_cost_basis = short_options.map(&:market_value).inject(0, &:+)


  long_stock_value = long_stocks.map(&:market_value).inject(0, &:+)
  short_stock_value = short_stocks.map(&:market_value).inject(0, &:+)
  long_option_value = long_options.map(&:market_value).inject(0, &:+)
  short_option_value = short_options.map(&:market_value).inject(0, &:+)

  p
  p '-' * 15
  p "ACCOUNT #{user.account}"
  p '-' * 15

  if long_stock_cost_basis != 0
    p "Long Stock: Value: $#{long_stock_value}  Cost Basis: $#{long_stock_cost_basis}  Return: #{((long_stock_value / long_stock_cost_basis) - 1).round(4) * 100}%"
  end

  if short_stock_cost_basis != 0
    p "Short Stock: Value: $#{short_stock_value}  Cost Basis: $#{short_stock_cost_basis}  Return: #{(1 - (short_stock_value / short_stock_cost_basis)).round(4) * 100}%"
  end

  if long_option_cost_basis != 0
    p "Long Options: Value: $#{long_option_value}  Cost Basis: $#{long_option_cost_basis}  Return: #{((long_option_value / long_option_cost_basis) - 1).round(4) * 100}%"
  end

  if short_option_cost_basis != 0
    p "Short Options: Value: $#{short_option_value}  Cost Basis: $#{short_option_cost_basis}  Return: #{(1 - (short_option_value / short_option_cost_basis)).round(4) * 100}%"
  end

  # Save to file
  File.open("snapshots/#{user.account}_#{Time.now.strftime('%Y-%m-%d')}_all_positions.txt",
            'w',
            encoding: 'ascii-8bit'
  ) { |f|
    f.write Marshal.dump(portfolio_values)
  }

  old_positions = Marshal.load(
    File.binread("snapshots/#{user.account}_2020-08-29_all_positions.txt")
  )

  Indicators::SMA.new(contract: portfolio_values.select { |c| c.symbol == 'AAPL' }.first.contract, dur: 50).call


  return

  # CHECK CLOSED POSITION PERFORMANCE
  long_stocks.each do |s|
    contract = s.contract
    # TODO: why won't the exchanges sent by IB work for historical data queries?
    contract.exchange = "SMART"
    # contract.verify!

    p "Checking hist data for #{contract.symbol}"

    results = nil
    contract.eod(duration: 50, timeout: 2) do |r|
      results = r #.each { |s| puts s.to_human }
    end

    p "BAD CONTRACTS: #{bad_contracts.count}"

  rescue Timeout::Error
    p "******ERROR: could not fetch data for #{contract}"
    bad_contracts << contract
  end


  # target = IB::Symbols::Stocks.aapl.verify!
  # target = long_stocks[6].contract.verify!
end

# Save to file
File.open("snapshots/#{Time.now.strftime('%Y-%m-%d')}_bad_contracts.txt", 'w') { |f|
  f.write bad_contracts.map(&:to_s).join("\n\n")
}

# Gateway.all_contracts is defined in lib/ib/account_infos.rb
# and is simply
# active_accounts.map(&:contracts).flat_map(&:itself).uniq(&:con_id)
#

