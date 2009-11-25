#!/usr/bin/env ruby

require 'sqlite3'

class Persistence
  @@backend = nil
  def self.db=(db)
    @@backend = db
  end
  def self.execute(*query)
    db.execute.call(query)
  end
end

class Column
  def initialize(name, kind, quals)
    @name, @kind = name, kind
    @quals = quals
  end
  
  def to_s
    qualifiers = @quals.join(" ").gsub("_", " ")
    if qualifiers == ""
      "#@name #@kind"
    else
      "#@name #@kind #{qualifiers}"
    end
  end
end


class Table
  @@columns = [Column.new(:id, :integer, [:primary_key])]

  def self.declare_column(name, kind, *quals)
    @@columns.push(Column.new(name, kind, quals))
  end

  def create
    table_name = self.class.name.downcase
    cols = @@columns.join(", ")
    
    "create table #{table_name} ( #{cols} );"
  end
end
