require File.expand_path('../../connect_db.rb', __FILE__)
require File.expand_path('../models/user.rb', __FILE__)

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'active_record/pg_generate_series'
