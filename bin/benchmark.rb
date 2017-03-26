# frozen_string_literal: true
require 'bundler/setup'
require 'active_record'
require 'activerecord-import'
require File.expand_path('../../connect_db.rb', __FILE__)
require File.expand_path('../../spec/models/user.rb', __FILE__)
require 'active_record/pg_generate_series'

require 'benchmark'

RECORD_NUM = 10_000

def build_user(num)
  User.new(name: "name#{num + 1}", age: num + 1, birth_date: Date.today + num + 1)
end

User.delete_all

GC.disable
Benchmark.bm(36) do |x|
  x.report('iteration of ActiveRecord::Base#save') do
    RECORD_NUM.times do |i|
      user = build_user(i)
      user.save(validate: false)
    end
  end

  x.report('bulk insert(activerecord-import)') do
    users = Array.new(RECORD_NUM) { |i| build_user(i) }
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
