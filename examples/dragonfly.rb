$LOAD_PATH.unshift File.expand_path(File.join(__FILE__, "..", "..", "lib"))

require 'tessa'

app = Dragonfly.app(:s3_test_bucket)

app.configure do
  datastore :aws_s3,
    bucket: "wcc-test-bucket",
    region: ENV['AWS_REGION'],
    prefix: "test-files/",
    credentials: {
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    }
end

puts "Uploading test..."
p uid = app.store("X" * 1_000)

puts "Downloading test..."
p app.fetch(uid).apply

puts "Deleting test..."
p app.destroy(uid)

puts "Download test after delete..."
begin
  p app.fetch(uid).apply
rescue Dragonfly::Job::Fetch::NotFound
  puts "Proper error raised."
end
