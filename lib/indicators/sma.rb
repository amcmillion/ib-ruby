module Indicators
  class SMA
    attr_reader :contract, :dur

    def initialize(contract:, dur:)
      @contract = contract
      @dur = dur
    end

    def call
      cont = contract
      cont.exchange = 'SMART'

      bars = nil
      cont.eod(duration: dur) do |results|
        bars = results
      end

      # data[n]: n days worth of bars

      sma = bars.map { |bar| bar.close }.inject(0, :+) / bars.length
      
      p "#{dur}-day SMA on #{bars.last.time} is #{sma}!"
    end
  end
end