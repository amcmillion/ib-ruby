require 'order_helper'


RSpec.describe IB::LimitIfTouched do
	before(:all) do
		verify_account
		ib = IB::Connection.new OPTS[:connection] do | gw| 
			gw.logger = mock_logger
			# put the most recent received OpenOrder-Message to an instance-variable
			gw.subscribe( :OpenOrder ){|msg| @the_open_order_message = msg}
		end
		ib.wait_for :NextValidId

		@the_order_price =  nil
		@the_trigger_price =  nil
		IB::Connection.current.clear_received :OpenOrder
		place_the_order do | last_price |

			@the_order_price = last_price.nil? ? 56 : last_price -2    # set a limit price that 
			# is well below the actual price
			# The Order will become visible only if the market-price is below the trigger-price
			#
			@the_trigger_price = @the_order_price + 1
			IB::LimitIfTouched.order price: @the_order_price , action: :buy, size: 100, 
				trigger_price: @the_trigger_price , account: ACCOUNT
		end
	end

		
	after(:all) { IB::Connection.current.send_message(:RequestGlobalCancel); close_connection; } 

	context  IB::Connection  do
		subject { IB::Connection.current }
		it( "received an OpenOrder message" ) { expect( subject.received[:OpenOrder]).to have_at_least(1).open_order_message  }
		it("received a Status message") { expect( subject.received[:OrderStatus]).to have_exactly(1).status_messages  }
		it("The correct OpenOrder exists") { expect(subject.received[:OpenOrder].last).to  eq @the_open_order_message }
	end

		context IB::Messages::Incoming::OpenOrder do
		subject{ @the_open_order_message }
		it_behaves_like 'OpenOrder message'
	end

	context IB::Order do

		subject{ @the_open_order_message.order }
#		subject{ IB::Connection.current.received[:OpenOrder].order.last }
		it_behaves_like 'Placed Order' 
		its( :aux_price ){ is_expected.not_to  be_zero }  # trigger-price => aux-price
		its( :action ){ is_expected.to  eq( :buy ) or eq( :sell ) }
		its( :order_type ){ is_expected.to  eq :limit_if_touched }
		its( :account ){ is_expected.to  eq ACCOUNT }
		its( :limit_price ){ is_expected.to be == @the_order_price }  # eq is not working, DibDecimal !eq Float
		its( :aux_price ){ is_expected.to  be == @the_trigger_price }
		its( :total_quantity ){ is_expected.to eq 100 }

	end

	context IB::Contract do

		subject{ @the_open_order_message.contract }
		it 'has proper contract accessor' do
			c = subject
			expect(c).to be_an IB::Contract
			expect(c.symbol).to eq  'WFC'
			expect(c.exchange).to eq 'SMART'
		end


	end	

#it 'has extended order_state attributes' do
# to generate the order:
# o = ForexLimit.order action: :buy, size: 15000, cash_qty: true
# c =  Symbols::Forex.eurusd
# C.place_order o, c



end # describe IB::Messages:Incoming

__END__


