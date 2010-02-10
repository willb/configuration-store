require 'sqlite3'

Mrg::Grid::Config::DBMIGRATIONS[2] = Proc.new do
  # the only change here is to ensure that the DirtyElement table has been created
  Rhubarb::Persistence::db.execute("PRAGMA user_version = 2")
end