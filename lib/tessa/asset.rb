module Tessa
  class Asset
    include Virtus.model

    attribute :id, Integer
    attribute :status, String
    attribute :strategy, String
    attribute :meta, Hash
    attribute :public_url, String
    attribute :private_url, String
    attribute :delete_url, String

  end
end
