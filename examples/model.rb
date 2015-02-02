$LOAD_PATH.unshift File.expand_path(File.join(__FILE__, "..", "..", "lib"))

require 'tessa'

app = Dragonfly.app(:custom_app)

app.configure do
  datastore :memory
end

class Asset
  extend Dragonfly::Model
  attr_accessor :file_uid

  dragonfly_accessor :file, app: :custom_app

  def initialize(uid: nil, file: nil)
    if uid
      @file_uid = uid
    else
      self.file = file
    end
  end

  def save
    save_dragonfly_attachments
    puts "[Asset#save]: TODO save to DB"
  end
end

asset = Asset.new(file: "TEST")

puts "Before save..."
p asset

asset.save

puts "After save..."
p asset

uid = asset.file_uid

puts "-----"

asset = Asset.new(uid: uid)
p asset.file
p asset.file.data
p asset.file.meta
