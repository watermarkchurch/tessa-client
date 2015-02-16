require 'pathname'
require 'json'
require 'dragonfly'

TEST_VIDEO_PATH = Pathname.new(File.expand_path(File.join(__FILE__, "..", "test.m4v")))

app = Dragonfly.app(:s3_test_bucket)

class VideoProperties

  def call(content)
    ffprobe_command = "ffprobe"
    raw_details = content.shell_eval do |path|
      "#{ffprobe_command} -v quiet -print_format json -show_format -show_streams #{path}"
    end
    parse_output(raw_details)
  end

  private

  def parse_output(raw)
    begin
      JSON.parse(raw)
    rescue JSON::ParserError => err
      $stderr.puts "Failed to probe video"
    end
  end
end

app.configure do
  datastore :memory

  analyser :video_properties, VideoProperties.new

  analyser :duration do |content|
    content.analyse(:video_properties)['format']['duration']
  end

  analyser :bit_rate do |content|
    content.analyse(:video_properties)['format']['bit_rate']
  end
end

id = app.store(TEST_VIDEO_PATH)
video = app.fetch(id)
p video.video_properties
p video.duration
p video.bit_rate

