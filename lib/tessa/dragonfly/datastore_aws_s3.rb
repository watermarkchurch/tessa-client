require 'aws-sdk'

Dragonfly::App.register_datastore(:aws_s3) { Tessa::Dragonfly::DatastoreAwsS3 }

module Tessa
  module Dragonfly
    class DatastoreAwsS3

      S3_PATH_SEPARATOR = "/"

      def initialize(options={})
        @credentials = initialize_credentials(options.fetch(:credentials))
        @region = options.fetch(:region)
        @bucket = options.fetch(:bucket)
        @prefix = options[:prefix]
      end

      def write(content, options={})
        uid = options[:path] || generate_uuid(content.name || 'file')

        store.put_object(
          bucket: @bucket,
          body: content.file,
          key: full_key(uid),
          metadata: content.meta
        )

        uid
      end

      def read(uid)
        object = store.get_object(bucket: @bucket, key: full_key(uid))
        if object
          [
            object.body.string,
            object.metadata
          ]
        end
      rescue Aws::S3::Errors::NoSuchKey
      end

      def destroy(uid)
        store.delete_object(
          bucket: @bucket,
          key: full_key(uid)
        )
        true
      end

      def store
        @store ||= initialize_store
      end

      private

      def full_key(uid)
        [
          @prefix || "",
          uid
        ].join
      end

      def generate_uuid(name)
        date = Date.today
        [
          date.strftime("%Y#{S3_PATH_SEPARATOR}%m#{S3_PATH_SEPARATOR}%d"),
          SecureRandom.uuid,
          name,
        ].join(S3_PATH_SEPARATOR)
      end

      def initialize_store
        Aws::S3::Client.new(region: @region, credentials: @credentials)
      end

      def initialize_credentials(credentials)
        case credentials
        when Aws::Credentials
          credentials
        when Hash
          Aws::Credentials.new(
            credentials[:access_key_id],
            credentials[:secret_access_key]
          )
        else
          raise "Invalid credentials: #{credentials.inspect}"
        end
      end

    end
  end
end
