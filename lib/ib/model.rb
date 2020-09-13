## Connection to Orientdb is established if the oriendb-client is
# present upon require if ib-ruby
# If ActiveOrient is not connected (ActiveOrient::Init.connect has not been called)
# lightweight tables are used
require 'ib/base_properties'
#require 'active-orient'
#if ActiveOrient::Model.orientdb.nil?
require 'ib/base'
require 'ib/db'
# require 'pg'

	IB::Model = IB::Base

return
#else
# 	require 'ib/orientdb'
#	IB::Model =  V #ActiveOrient::Base
# Load DB config, determine correct environment
db_file = Pathname.new(__FILE__).realpath.dirname + '../../db/config.yml'
raise "Unable to find DB config file: #{db_file}" unless db_file.exist?

db_config = YAML::load_file(db_file)
db_config = db_config['development'] # TODO: dynamic ENV

IB::DB.connect db_config

# Establish connection to test DB
# IB::DB.connect(db_config)
# 	puts " IB-Ruby is run in PG-Mode"
#end
module IB
  # IB Models can be either lightweight (tableless) or database-backed.
p 'IB.db_backed?'
p IB.db_backed?

 IB::Model =  IB.db_backed? ? ActiveRecord::Base : IB::Base

end
