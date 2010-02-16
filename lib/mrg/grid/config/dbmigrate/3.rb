require 'sqlite3'

Mrg::Grid::Config::DBMIGRATIONS[3] = Proc.new do
  Rhubarb::Persistence::db.execute("ALTER TABLE node ADD COLUMN last_checkin integer default 0")
  Rhubarb::Persistence::db.execute("UPDATE node set last_checkin = ?", 0)
  Rhubarb::Persistence::db.execute("PRAGMA user_version = 3")
end