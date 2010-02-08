require 'sqlite3'

Mrg::Grid::Config::DBMIGRATIONS[1] = Proc.new do
  Rhubarb::Persistence::db.execute("ALTER TABLE node ADD COLUMN provisioned boolean default true")
  Rhubarb::Persistence::db.execute("UPDATE node set provisioned = ?", true)
  Rhubarb::Persistence::db.execute("PRAGMA user_version = 1")
end