require 'rails_helper'

RSpec.describe Tessa do

  describe '#find_assets' do
    it 'returns AssetFailure for singular asset' do
      result = Tessa.find_assets(1)

      expect(result).to be_a(Tessa::Asset::Failure)
      expect(result.message).to eq("The service is unavailable at this time.")
    end

    it 'returns AssetFailure array for multiple assets' do
      result = Tessa.find_assets([1, 2, 3])

      expect(result.count).to eq(3)
      result.each do |r|
        expect(r).to be_a(Tessa::Asset::Failure)
        expect(r.message).to eq("The service is unavailable at this time.")
      end
    end
  end
end