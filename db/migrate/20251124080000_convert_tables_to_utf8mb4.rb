class ConvertTablesToUtf8mb4 < ActiveRecord::Migration[6.1]
  def up
    # Get all tables in the database
    tables = ActiveRecord::Base.connection.tables
    
    tables.each do |table|
      # Convert table to utf8mb4
      execute "ALTER TABLE #{table} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
      
      # Also update the default charset for the table
      execute "ALTER TABLE #{table} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    end
    
    # Update database default charset
    database_name = ActiveRecord::Base.connection.current_database
    execute "ALTER DATABASE #{database_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
  end

  def down
    # Get all tables in the database
    tables = ActiveRecord::Base.connection.tables
    
    tables.each do |table|
      # Convert table back to utf8mb3
      execute "ALTER TABLE #{table} CONVERT TO CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci"
      
      # Also update the default charset for the table
      execute "ALTER TABLE #{table} DEFAULT CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci"
    end
    
    # Update database default charset
    database_name = ActiveRecord::Base.connection.current_database
    execute "ALTER DATABASE #{database_name} CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci"
  end
end
