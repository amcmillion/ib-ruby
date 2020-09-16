
closed_positions = old_positions.select { |old|
  old.stock? &&
    !portfolio_values.map(&:contract).map(&:symbol).include?(old.symbol)
}

total_pnl = 0
positions_gaining_since_closed = []
closed_positions.map { |closed|
  begin
    if portfolio_values.map(&:contract).map(&:symbol).include?(closed.symbol)
      p "*****ERROR: Closed position #{closed.symbol} was found in current portfolio!"
    else
      p "Closed position: #{closed.position} #{closed.contract.symbol} #{closed.contract.class}"
      closed_contract = closed.contract
      closed_contract.exchange = "SMART"

      current_price = nil
      closed_contract.eod do |results|
        current_price = results.first.close
      end

      delta_usd = (current_price * closed.position) - closed.market_value
      # delta_perc = (current_price / closed.market_)
      p "Closed value = $#{closed.market_value}"
      p "Current value = $#{(current_price * closed.position)}"
      p "Missed P/L$ : #{delta_usd}"
      # p "Missed P/L% : #{current_value}"
      total_pnl += delta_usd

      if delta_usd.positive?
        positions_gaining_since_closed << {
          symbol: closed.symbol,
          closed_at: closed.market_price,
          current_price: current_price,
          delta_usd: delta_usd
        }
      end
    end
  rescue Timeout::Error
  end
}

p "RESULT: Closed positions resulted in a P/L of $#{total_pnl}"