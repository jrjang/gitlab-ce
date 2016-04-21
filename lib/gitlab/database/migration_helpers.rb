module Gitlab
  module Database
    module MigrationHelpers
      # Creates a new index, concurrently when supported
      #
      # On PostgreSQL this method creates an index concurrently, on MySQL this
      # creates a regular index.
      #
      # Example:
      #
      #     add_concurrent_index :users, :some_column
      #
      # See Rails' `add_index` for more info on the available arguments.
      def add_concurrent_index(*args)
        if Database.postgresql?
          args = args + [ { algorithm: :concurrently } ]
        end

        add_index(*args)
      end

      def add_column_with_default_in_batches(table, column, type, default, allow_null = true)
        quoted_table = quote_table_name(table)
        quoted_def   = quote(default)
        processed    = 0

        total = exec_query("SELECT COUNT(*) AS count FROM #{quoted_table};").
          to_hash.
          first['count'].
          to_i

        # Update in batches of 5% with an upper limit of 5000 rows.
        batch_size = (total / 100.0) * 5.0

        if batch_size > 5000
          batch_size = 5000
        end

        add_column(table, column, default: nil)

        while processed < total
          execute(<<-EOF)
UPDATE #{quoted_table}
SET #{column} = #{quoted_def}
WHERE id IN (
  SELECT id
  FROM #{quoted_table}
  WHERE #{column} IS NULL
  LIMIT #{batch_size}
);
          EOF

          processed += batch_size
        end

        change_column_default(table, column, default)

        # Update any columns added between updating the last batch and changing
        # the column's default.
        execute(<<-EOF)
UPDATE #{quoted_table}
SET #{column} = #{quoted_def}
WHERE #{column} IS NULL;
        EOF

        change_column_null(table, column, false) unless allow_null
      end
    end
  end
end
