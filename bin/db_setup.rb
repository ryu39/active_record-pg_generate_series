# frozen_string_literal: true

require 'erb'
require 'yaml'
require 'active_record'

config_file = File.expand_path('../../database.yml', __FILE__)
config = YAML.load(ERB.new(IO.read(config_file)).result)['db']

ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres'))
ActiveRecord::Base.connection.drop_database(config['database'])
ActiveRecord::Base.connection.create_database(config['database'])
ActiveRecord::Base.establish_connection(config)

ActiveRecord::Base.connection.create_table :users do |t|
  t.string :type
  t.string :name, null: false
  t.integer :age, null: false
  t.date :birth_date, null: false
  t.boolean :disabled, null: false, default: false

  t.timestamps
end
