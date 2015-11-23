require 'webmock/rspec'
require 'metriks'
require 'metriks-addons/signalfx_reporter'

describe "Smoke test" do
  before(:all) do
    stub_request(:any, "http://localhost:4242")
  end

  before(:each) do
    @registry = Metriks::Registry.new
    @reporter = MetriksAddons::SignalFxReporter.new(
      "123456789",
      [{:env => "test"}],
      { :registry => @registry, :batch_size => 3})
  end

  after(:each) do
    @reporter.stop
    @registry.stop
  end

  it "meter" do
    @registry.meter('meter.testing').mark
    datapoints = @reporter.get_datapoints
    expect(datapoints[:counters].size).to eql(1)
    expect(datapoints[:counters][0][:metric]).to eql("meter.testing.count")
    expect(datapoints[:counters][0][:value]).to eql(1)
    expect(datapoints[:counters][0][:dimensions]).to include(:env => "test")
    expect(datapoints[:counters][0][:timestamp]).not_to be_nil
  end

  it "counters" do
    @registry.counter('counter.testing').increment
    datapoints = @reporter.get_datapoints
    expect(datapoints[:counters].size).to eql(1)
    expect(datapoints[:counters][0][:metric]).to eql("counter.testing.count")
    expect(datapoints[:counters][0][:value]).to eql(1)
    expect(datapoints[:counters][0][:dimensions]).to include(:env => "test")
    expect(datapoints[:counters][0][:timestamp]).not_to be_nil
  end

  it "timer" do
    @registry.timer('timer.testing').update(1.5)
    datapoints = @reporter.get_datapoints
    expect(datapoints[:counters].size).to eql(1)
    expect(datapoints[:gauges].size).to eql(3)
    expect(datapoints[:counters][0][:metric]).to eql("timer.testing.count")
    expect(datapoints[:counters][0][:value]).to eql(1)
    expect(datapoints[:counters][0][:dimensions]).to include(:env => "test")
    expect(datapoints[:counters][0][:timestamp]).not_to be_nil

    expect(datapoints[:gauges][0][:metric]).to eql("timer.testing.min")
    expect(datapoints[:gauges][0][:value]).not_to be_nil
    expect(datapoints[:gauges][0][:dimensions]).to include(:env => "test")
    expect(datapoints[:gauges][0][:timestamp]).not_to be_nil

    expect(datapoints[:gauges][1][:metric]).to eql("timer.testing.max")
    expect(datapoints[:gauges][1][:value]).not_to be_nil
    expect(datapoints[:gauges][1][:dimensions]).to include(:env => "test")
    expect(datapoints[:gauges][1][:timestamp]).not_to be_nil

    expect(datapoints[:gauges][2][:metric]).to eql("timer.testing.mean")
    expect(datapoints[:gauges][2][:value]).not_to be_nil
    expect(datapoints[:gauges][2][:dimensions]).to include(:env => "test")
    expect(datapoints[:gauges][2][:timestamp]).not_to be_nil
  end

  it "gauges" do
    @registry.gauge('gauge.testing') { 123 }
    datapoints = @reporter.get_datapoints
    expect(datapoints[:gauges].size).to eql(1)
    expect(datapoints[:gauges][0][:metric]).to eql("gauge.testing.value")
    expect(datapoints[:gauges][0][:value]).to eql(123)
    expect(datapoints[:gauges][0][:dimensions]).to include(:env => "test")
    expect(datapoints[:gauges][0][:timestamp]).not_to be_nil
  end
end

describe "Rest Client" do
  before(:each) do
    @registry = Metriks::Registry.new
    @reporter = MetriksAddons::SignalFxReporter.new(
      "123456789",
      [{:key => "env", :value => "test"}],
      { :registry => @registry, :batch_size => 3})
      stub_request(:post, "https://ingest.signalfx.com/v2/datapoint").
        with(:body => "\n0\x12\x14gauges.testing.value\x18\xE0\xA8\xBF\xA4\x93*\"\x02\x18{(\x002\v\n\x03env\x12\x04test\n4\x12\x18counters.testing.0.count\x18\xE0\xA8\xBF\xA4\x93*\"\x02\x18\x01(\x012\v\n\x03env\x12\x04test\n4\x12\x18counters.testing.1.count\x18\xE0\xA8\xBF\xA4\x93*\"\x02\x18\x01(\x012\v\n\x03env\x12\x04test\n4\x12\x18counters.testing.2.count\x18\xE0\xA8\xBF\xA4\x93*\"\x02\x18\x01(\x012\v\n\x03env\x12\x04test",
             :headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'212', 'Content-Type'=>'application/x-protobuf', 'User-Agent'=>'signalfx-ruby-client/0.1.0', 'X-Sf-Token'=>'123456789'}).
        to_return(:status => 200, :body => "", :headers => {})
  end

  it "Send metricwise" do
    for i in 0..2 do
      @registry.counter("counters.testing.#{i}").increment
    end
    @registry.gauge("gauges.testing") { 123 }
    @reporter.submit @reporter.get_datapoints
    expect(a_request(:post, "https://ingest.signalfx.com/v2/datapoint")).to have_been_made
  end
end
