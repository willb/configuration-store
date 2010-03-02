# database migrations for wallaby
#
# Copyright (c) 2009--2010 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'sqlite3'

Mrg::Grid::Config::DBMIGRATIONS[4] = Proc.new do
  Rhubarb::Persistence::db.execute("ALTER TABLE node ADD COLUMN last_updated_version integer default 0")
  Rhubarb::Persistence::db.execute("UPDATE node set last_updated_version = ?", 0)
  Rhubarb::Persistence::db.execute("PRAGMA user_version = 4")
end