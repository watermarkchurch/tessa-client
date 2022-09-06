RSpec.shared_examples_for "remote call macro" do |method, path, return_type|
  let(:remote_response) { {} }
  let(:faraday_stubs) {
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.send(method, path) { |env| [200, {}, remote_response.to_json] }
    end
  }
  let(:connection) { Faraday.new { |f| f.adapter :test, faraday_stubs } }
  let(:call_args) { { connection: connection } }

  it "calls #{method} method with #{path}" do
    expect(connection).to receive(method).with(path, any_args).and_call_original
    call
  end

  context "with no connection passed" do
    let(:call_args) { {} }

    it "defaults connection to Tessa.config.connection" do
      expect(Tessa.config).to receive(:connection).and_return(connection)
      expect(connection).to receive(method).and_call_original
      call
    end
  end

  context "when response is not successful" do
    let(:connection) { Tessa::FakeConnection.new }

    it "raises Tessa::RequestFailed" do
      expect{ call }.to raise_error { |error|
        expect(error).to be_a(Tessa::RequestFailed)
      }
    end
  end

  it "returns an instance of #{return_type}" do
    expect(call).to be_a(return_type)
  end
end

