# ActiveRecord::PgGenerateSeries

[![Build Status](https://travis-ci.org/ryu39/active_record-pg_generate_series.svg?branch=master)](https://travis-ci.org/ryu39/active_record-pg_generate_series)

This gem adds a feature which inserts records using PostgreSQL generate_series function to ActiveRecord.

Insertion using generate_series funciton is very fast.
It is about 300-400 times faster than iteration of ActiveRecord::Base#save and 30-40 times faster than bulk insert. (In authors env)

## Benchmark

I compared to iteration of ActiveRecord::Base#save(without validation) and 
bulk insertion using [activerecord-import](https://github.com/zdennis/activerecord-import).

The average(3 times) of inserting 10,000 records is shown as follows.
This is measured in author's PC(MacBook Pro Retina 13-inch Early 2015).

| Target                           | Time(sec) |
|:---------------------------------|----------:|
| ActiveRecord#save                |    37.442 |
| activerecord-import              |     3.149 |
| active_record-pg_generate_series |     0.092 |

You can run benchmark with following commands.

    $ docker-compose up -d
    $ ./bin/setup
    $ ruby bin/benchmark.rb

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_record-pg_generate_series'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_record-pg_generate_series

## Usage

You can insert records by calling `ActiveRecord::Base.insert_using_generate_series`.
This function requires 3 parameters, `first`, `last` and block.
The parameters `first` and `last` are passed to PostgreSQL GENERATE_SERIES function.
The block specifies values of insert records.

Please see this example.

```ruby
# User is a subclass of ActiveRecord::Base
User.insert_using_generate_series(1, 10) do |sql|
  sql.name = 'username'
  sql.age = 16
  sql.birth_date = Date.new(2000, 1, 1)
end

p User.all
# => #<ActiveRecord::Relation 
#     [#<User id: 1, type: nil, name: "username", age: 16, birth_date: "2000-01-01", disabled: false, created_at: "2016-11-23 08:52:25", updated_at: "2016-11-23 08:52:25">, 
#      #<User id: 2, type: nil, name: "username", age: 16, birth_date: "2000-01-01", disabled: false, created_at: "2016-11-23 08:52:25", updated_at: "2016-11-23 08:52:25">, 
# :
#      #<User id: 10, type: nil, name: "username", age: 16, birth_date: "2000-01-01", disabled: false, created_at: "2016-11-23 08:52:25", updated_at: "2016-11-23 08:52:25">]>
```

Note that `created_at` and `updated_at` are set automatically.
You can overwrite these values in block.

You can also use sequence value generated by GENERATE_SERIES function using `#raw` method with `seq` in sql block.

```ruby
User.insert_using_generate_series(1, 10) do |sql|
  sql.name = raw("'username' || seq")
  sql.age = raw("seq")
  sql.birth_date = raw("'1999-12-31'::date + seq")
  sql.disabled = raw("CASE seq % 2 WHEN 0 THEN true ELSE false END")
end

p User.all
# => #<ActiveRecord::Relation 
#     [#<User id: 11, type: nil, name: "username1", age: 1, birth_date: "2000-01-01", disabled: false, created_at: "2016-11-23 09:03:12", updated_at: "2016-11-23 09:03:12">, 
#      #<User id: 12, type: nil, name: "username2", age: 2, birth_date: "2000-01-02", disabled: true, created_at: "2016-11-23 09:03:12", updated_at: "2016-11-23 09:03:12">, 
# :
#      #<User id: 20, type: nil, name: "username10", age: 10, birth_date: "2000-01-10", disabled: true, created_at: "2016-11-23 09:03:12", updated_at: "2016-11-23 09:03:12">]>
```

When you use `#raw` method, please take care of sql injection because `#raw` method does not sanitize given string.

### STI support

When target is STI subclass, the type value(default is `type` column) is set automatically.

```ruby
# AdminUser is a subclass of User.
AdminUser.insert_using_generate_series(1, 10) do |sql|
  sql.name = 'admin username'
  sql.age = 16
  sql.birth_date = Date.new(2000, 1, 1)
end

p AdminUser.all
# => #<ActiveRecord::Relation 
#     [#<AdminUser id: 21, type: "AdminUser", name: "admin username", age: 16, birth_date: "2000-01-01", disabled: false, created_at: "2016-11-23 09:17:22", updated_at: "2016-11-23 09:17:22">, #<AdminUser id: 22, type: "AdminUser", name: "admin username", age: 16, birth_date: "2000-01-01", disabled: false, created_at: "2016-11-23 09:17:22", updated_at: "2016-11-23 09:17:22">,  21, type: "AdminUser", name: "admin username", age: 16, birth_date: "2000-01-01", disabled: false, created_at: "2016-11-23 09:17:22", updated_at: "2016-11-23 09:17:22">, 
#      #<AdminUser id: 22, type: "AdminUser", name: "admin username", age: 16, birth_date: "2000-01-01", disabled: false, created_at: "2016-11-23 09:17:22", updated_at: "2016-11-23 09:17:22">, 
# :
#      #<AdminUser id: 30, type: "AdminUser", name: "admin username", age: 16, birth_date: "2000-01-01", disabled: false, created_at: "2016-11-23 09:17:22", updated_at: "2016-11-23 09:17:22">]>
```

### Options

#### Step

You can change step value of GENERATE_SERISE function (Default: 1) with `step` option.

```ruby
User.insert_using_generate_series(1, 10, step: 5) do |sql|
  sql.name = raw("'username' || seq")
  sql.age = raw("seq")
  sql.birth_date = raw("'1999-12-31'::date + seq")
  sql.disabled = raw("CASE seq % 2 WHEN 0 THEN true ELSE false END")
end

p User.all
# => #<ActiveRecord::Relation 
#     [#<User id: 31, type: nil, name: "username1", age: 1, birth_date: "2000-01-01", disabled: false, created_at: "2016-11-23 10:00:47", updated_at: "2016-11-23 10:00:47">, 
#      #<User id: 32, type: nil, name: "username6", age: 6, birth_date: "2000-01-06", disabled: true, created_at: "2016-11-23 10:00:47", updated_at: "2016-11-23 10:00:47">]>
```

#### Sequence name

Also, you can change sequence name of GENERATE_SERISE function (Default: `seq`) with `seq_name` option.

```ruby
User.insert_using_generate_series(1, 10, seq_name: 'new_seq') do |sql|
  sql.name = raw("'username' || new_seq")
  sql.age = raw("new_seq")
  sql.birth_date = raw("'1999-12-31'::date + new_seq")
  sql.disabled = raw("CASE new_seq % 2 WHEN 0 THEN true ELSE false END")
end

p User.all
# => #<ActiveRecord::Relation 
#     [#<User id: 33, type: nil, name: "username1", age: 1, birth_date: "2000-01-01", disabled: false, created_at: "2016-11-23 10:26:30", updated_at: "2016-11-23 10:26:30">, 
#      #<User id: 34, type: nil, name: "username2", age: 2, birth_date: "2000-01-02", disabled: true, created_at: "2016-11-23 10:26:30", updated_at: "2016-11-23 10:26:30">, 
#      #<User id: 35, type: nil, name: "username3", age: 3, birth_date: "2000-01-03", disabled: false, created_at: "2016-11-23 10:26:30", updated_at: "2016-11-23 10:26:30">, 
#      #<User id: 36, type: nil, name: "username4", age: 4, birth_date: "2000-01-04", disabled: true, created_at: "2016-11-23 10:26:30", updated_at: "2016-11-23 10:26:30">, 
#      #<User id: 37, type: nil, name: "username5", age: 5, birth_date: "2000-01-05", disabled: false, created_at: "2016-11-23 10:26:30", updated_at: "2016-11-23 10:26:30">, 
#      #<User id: 38, type: nil, name: "username6", age: 6, birth_date: "2000-01-06", disabled: true, created_at: "2016-11-23 10:26:30", updated_at: "2016-11-23 10:26:30">, 
#      #<User id: 39, type: nil, name: "username7", age: 7, birth_date: "2000-01-07", disabled: false, created_at: "2016-11-23 10:26:30", updated_at: "2016-11-23 10:26:30">, 
#      #<User id: 40, type: nil, name: "username8", age: 8, birth_date: "2000-01-08", disabled: true, created_at: "2016-11-23 10:26:30", updated_at: "2016-11-23 10:26:30">, 
#      #<User id: 41, type: nil, name: "username9", age: 9, birth_date: "2000-01-09", disabled: false, created_at: "2016-11-23 10:26:30", updated_at: "2016-11-23 10:26:30">, 
#      #<User id: 42, type: nil, name: "username10", age: 10, birth_date: "2000-01-10", disabled: true, created_at: "2016-11-23 10:26:30", updated_at: "2016-11-23 10:26:30">]>
```

#### Debug

When `insert_using_generate_series` is called with `debug` option, it does not execute sql but returns sql to be executed.

```ruby
sql = User.insert_using_generate_series(1, 10, debug: true) do |sql|
  sql.name = raw("'username' || seq")
  sql.age = raw("seq")
  sql.birth_date = raw("'1999-12-31'::date + seq")
  sql.disabled = raw("CASE seq % 2 WHEN 0 THEN true ELSE false END")
end

puts sql
# => INSERT INTO
#    "users" ("created_at","updated_at","name","age","birth_date","disabled")
#  SELECT
#    '2016-11-23 09:32:29.750549',
#    '2016-11-23 09:32:29.750549',
#    'username' || seq,
#    seq,
#    '1999-12-31'::date + seq,
#    CASE seq % 2 WHEN 0 THEN true ELSE false END
#  FROM
#    GENERATE_SERIES(1, 10, 1) AS "seq"
#  ;
```

## Development

First docker and docker-compose is required.

After checking out the repo, run `bin/setup` to install dependencies. 
Then, run `rake spec` to run the tests. 
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 
To release a new version, update the version number in `version.rb`, 
and then run `bundle exec rake release`, which will create a git tag for the version, 
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ryu39/active_record-pg_generate_series. 
This project is intended to be a safe, welcoming space for collaboration, 
and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

