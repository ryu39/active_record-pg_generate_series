# frozen_string_literal: true

require 'active_record/pg_generate_series/sql_builder'

module ActiveRecord
  module PgGenerateSeries
    # A ActiveRecord::Base extension module to use PostgreSQL GENERATE_SERIES function.
    module Extension
      # Execute INSERT SQL using GENERATE_SERIES function
      #
      # @param [Integer] first Required, first value of GENERATE_SERIES.
      # @param [Integer] last Required, last value of GENERATE SERIES.
      # @param [Integer] step Optional, step value of GENERATE_SERIES, default is 1.
      # @param [String, Symbol] seq_name Optional, name of GENERATE_SERIES sequence, default is :seq.
      # @param [boolean] debug Optional, if true then sql is returned, not executed.
      # @param [Proc] block Required, block for setting selected columns.
      def insert_using_generate_series(first, last, step: 1, seq_name: :seq, debug: false, &block)
        builder = ActiveRecord::PgGenerateSeries::SqlBuilder.new(self, first, last, step, seq_name)

        builder.send("#{inheritance_column}=", sti_name) unless descends_from_active_record?
        Time.current.tap do |now|
          builder.created_at = now if column_names.include?('created_at')
          builder.updated_at = now if column_names.include?('updated_at')
        end
        builder.instance_exec(builder, &block)

        sql = builder.to_sql
        debug ? sql : connection.execute(sql)
      end
    end
  end
end
