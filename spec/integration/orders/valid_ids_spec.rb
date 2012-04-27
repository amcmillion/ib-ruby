require 'order_helper'

shared_examples_for 'Received single id' do
  subject { @ib.received[:NextValidId].first }

  after(:all) { clean_connection }

  it { @ib.received[:NextValidId].should have_exactly(1).message }

  it 'receives next valid for Order placement' do
    subject.should be_an IB::Messages::Incoming::NextValidId
    subject.local_id.should be_an Integer
    @id[:at_connect] ||= subject.local_id # just assign once
  end

  it 'logs next valid order id' do
    should_log /Got next valid order id/
  end
end

shared_examples_for 'Received single id after request' do
  subject { @ib.received[:NextValidId].first }

  it_behaves_like 'Received single id'

  it 'no new id is generated by this request' do
    subject.local_id.should == @id[:at_connect]
  end

  it 'does not receive :OpenOrderEnd message' do
    @ib.received[:OpenOrderEnd].should be_empty
  end

  it 'does not reconnect to server' do
    should_not_log /Connected to server/
  end
end

describe 'Ids valid for Order placement', :connected => true, :integration => true do

  before(:all) do
    verify_account
    @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
    @ib.wait_for :NextValidId, 3 # , :OpenOrderEnd
    @id = {} # Moving id between contexts. Feels dirty.
  end

  after(:all) { close_connection }

  context 'at connect' do

    it_behaves_like 'Received single id'

    it 'receives also :OpenOrderEnd message', :pending => 'not in GW 924.3a' do
      @ib.received[:OpenOrderEnd].should have_exactly(1).message
      @ib.received[:OpenOrderEnd].first.should be_an IB::Messages::Incoming::OpenOrderEnd
    end

    it 'logs connection notification' do
      should_log /Connected to server, version: .., connection time/
    end
  end # at connect

  context 'Requesting valid order id' do
    before(:all) do
      @ib.send_message :RequestIds
      @ib.wait_for :NextValidId
    end

    it_behaves_like 'Received single id after request'
  end # Requesting valid order ids

  context 'Requested number of valid ids is just silently ignored by TWS' do
    before(:all) do
      @ib.send_message :RequestIds, :number => 5
      @ib.wait_for :NextValidId
    end

    it_behaves_like 'Received single id after request'
  end # number of ids is silently ignored

end # Ids valid for Order placement
