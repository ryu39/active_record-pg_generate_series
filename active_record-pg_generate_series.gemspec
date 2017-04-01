lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record/pg_generate_series/version'

Gem::Specification.new do |spec|
  spec.name          = 'active_record-pg_generate_series'
  spec.version       = ActiveRecord::PgGenerateSeries::VERSION
  spec.authors       = ['ryu39']
  spec.email         = ['dev.ryu39@gmail.com']

  spec.summary       = 'Add a feature which inserts records using PostgreSQL generate_series function to ActiveRecord'
  spec.description   = <<EOS.tr("\n", ' ')
This gem adds a feature which inserts records using PostgreSQL generate_series function to ActiveRecord.
Insertion using generate_series function is very fast, so it is useful
when you want to insert simple but many and many record, e.g. prepare for performance test.
EOS
  spec.homepage      = 'https://github.com/ryu39/active_record-pg_generate_series'
  spec.license       = 'MIT'

  spec.files         = %w(LICENSE.txt) + Dir['lib/**/*.rb']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activerecord'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '>= 3.5'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'activerecord-import'
end
