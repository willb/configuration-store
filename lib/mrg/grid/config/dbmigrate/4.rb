require 'sqlite3'

Mrg::Grid::Config::DBMIGRATIONS[4] = Proc.new do
  Rhubarb::Persistence::db.execute("ALTER TABLE node ADD COLUMN last_updated_version integer default 0")
  Rhubarb::Persistence::db.execute("UPDATE node set last_updated_version = ?", 0)
  Rhubarb::Persistence::db.execute("PRAGMA user_version = 4")
end