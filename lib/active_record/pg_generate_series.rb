# frozen_string_literal: true

require 'active_record'
require 'active_record/pg_generate_series/version'
require 'active_record/pg_generate_series/extension'

ActiveRecord::Base.extend ActiveRecord::PgGenerateSeries::Extension
