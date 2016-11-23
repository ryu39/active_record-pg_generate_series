require 'forwardable'

module ActiveRecord
  module PgGenerateSeries
    class SqlBuilder
      extend Forwardable
      def_delegators :@ar_class, :connection, :sanitize, :quoted_table_name

      def initialize(ar_class, first, last, step, seq_name)
        @ar_class = ar_class
        @first = first
        @last = last
        @step = step
        @seq_name = seq_name
        @select_items = {}

        ar_class.column_names.each do |col|
          define_singleton_method "#{col}=" do |val|
            @select_items[col] = val
          end
        end
      end

      def to_sql
        <<EOS
INSERT INTO
  #{quoted_table_name} (#{@select_items.keys.map { |col| connection.quote_column_name(col) }.join(',')})
SELECT
  #{@select_items.map { |_, val| "#{val.is_a?(Raw) ? val.str : sanitize(val)}" }.join(",\n  ")}
FROM
  GENERATE_SERIES(#{@first.to_i}, #{@last.to_i}, #{@step.to_i}) AS #{connection.quote_column_name(@seq_name)}
;
EOS
      end

      private

      class Raw
        attr_reader :str

        def initialize(str)
          @str = str
        end
      end

      def raw(str)
        Raw.new(str)
      end
    end
  end
end
