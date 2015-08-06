require 'webmock/rspec'
require 'metriks'
require 'metriks/signalfx_reporter'

describe "Rest Client" do
  before(:each) do
    @registry = Metriks::Registry.new
    @reporter = Metriks::SignalFxReporter.new(
      'http://localhost:4242', 
      "123456789",
      "ABCD",
      {:env => "test"},
      { :registry => @registry, :batch_size => 3})
    stub_request(:post, "http://localhost:4242/api/datapoint?orgid=ABCD").
      with(:body => /^\{.*\}$/).
      to_return(:status => 200, :body => "", :headers => {})
  end

  it "Send metricwise" do
    for i in 0..2 do
      @registry.counter("counter.testing.#{i}").increment
    end
    @registry.gauge("gauge.testing")
    @reporter.submit @reporter.get_datapoints
    expect(a_request(:post, "http://localhost:4242/api/datapoint?orgid=ABCD")).to have_been_made
  end
end
