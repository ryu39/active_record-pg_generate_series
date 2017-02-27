# frozen_string_literal: true
require 'bundler/setup'
require 'active_record'
require 'activerecord-import'
require File.expand_path('../../connect_db.rb', __FILE__)
require File.expand_path('../../spec/models/user.rb', __FILE__)
require 'active_record/pg_generate_series'

require 'benchmark'

RECORD_NUM = 10_000

User.delete_all

GC.disable
Benchmark.bm(36) do |x|
  x.report('iteration of ActiveRecord::Base#save') do
    RECORD_NUM.times do |i|
      user = User.new(name: "name#{i + 1}", age: i + 1, birth_date: Date.today + i + 1)
      user.save(validate: false)
    end
  end

  x.report('bulk insert(activerecord-import)') do
    users = RECORD_NUM.times.map do |i|
      User.new(name: "name#{i + 1}", age: i + 1, birth_date: Date.today + i + 1)
    end
    User.import(users)
  end

  x.report('active_record-pg_generate_series') do
    User.insert_using_generate_series(1, RECORD_NUM) do |sql|
      sql.name = raw("'name' || seq")
      sql.age = raw('seq')
      sql.birth_date = raw("'2000-01-01'::date + seq")
    end
  end
end
GC.enable

User.delete_all
