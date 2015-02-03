$LOAD_PATH.unshift File.expand_path(File.join(__FILE__, "..", "..", "lib"))

require 'tessa'
require 'active_record'
require 'sqlite3'

app = Dragonfly.app(:custom_app)

app.configure do
  datastore :memory
end

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'example.db'
)

ActiveRecord::Base.connection.execute(<<-SQL)
drop table if exists assets
create table
assets(
  id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
  file_uid TEXT
)
SQL

class Asset < ActiveRecord::Base
  extend Dragonfly::Model
  dragonfly_accessor :file, app: :custom_app
end

asset = Asset.new(file: "TEST")
asset.save

p Asset.last
p Asset.last.file
p Asset.last.file.data
p Asset.last.file.meta
