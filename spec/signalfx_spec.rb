require 'webmock/rspec'
require 'metriks'
require 'metriks/signalfx_reporter'

describe "Smoke test" do
  before(:all) do
    stub_request(:any, "http://localhost:4242")
  end

  before(:each) do
    @registry = Metriks::Registry.new
    @reporter = Metriks::SignalFxReporter.new(
      'http://localhost:4242', 
      "123456789",
      "ABCD",
      {:env => "test"},
      { :registry => @registry, :batch_size => 3})
  end

  after(:each) do
    @reporter.stop
    @registry.stop
  end

  it "meter" do
    @registry.meter('meter.testing').mark
    datapoints = @reporter.get_datapoints
    expect(datapoints[:counter].size).to eql(5)
    expect(datapoints[:counter][0][:metric]).to eql("meter.testing.count")
    expect(datapoints[:counter][0][:value]).to eql(1)
    expect(datapoints[:counter][0][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][0][:timestamp]).not_to be_nil

    expect(datapoints[:counter][1][:metric]).to eql("meter.testing.one_minute_rate")
    expect(datapoints[:counter][1][:value]).not_to be_nil
    expect(datapoints[:counter][1][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][1][:timestamp]).not_to be_nil

    expect(datapoints[:counter][2][:metric]).to eql("meter.testing.five_minute_rate")
    expect(datapoints[:counter][2][:value]).to eql(0.0)
    expect(datapoints[:counter][2][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][2][:timestamp]).not_to be_nil

    expect(datapoints[:counter][3][:metric]).to eql("meter.testing.fifteen_minute_rate")
    expect(datapoints[:counter][3][:value]).to eql(0.0)
    expect(datapoints[:counter][3][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][3][:timestamp]).not_to be_nil

    expect(datapoints[:counter][4][:metric]).to eql("meter.testing.mean_rate")
    expect(datapoints[:counter][4][:value]).not_to be_nil
    expect(datapoints[:counter][4][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][4][:timestamp]).not_to be_nil
  end

  it "counter" do
    @registry.counter('counter.testing').increment
    datapoints = @reporter.get_datapoints
    expect(datapoints[:counter].size).to eql(1)
    expect(datapoints[:counter][0][:metric]).to eql("counter.testing.count")
    expect(datapoints[:counter][0][:value]).to eql(1)
    expect(datapoints[:counter][0][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][0][:timestamp]).not_to be_nil
  end

  it "timer" do
    @registry.timer('timer.testing').update(1.5)
    datapoints = @reporter.get_datapoints
    expect(datapoints[:counter].size).to eql(11)
    expect(datapoints[:counter][0][:metric]).to eql("timer.testing.count")
    expect(datapoints[:counter][0][:value]).to eql(1)
    expect(datapoints[:counter][0][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][0][:timestamp]).not_to be_nil

    expect(datapoints[:counter][1][:metric]).to eql("timer.testing.one_minute_rate")
    expect(datapoints[:counter][1][:value]).not_to be_nil
    expect(datapoints[:counter][1][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][1][:timestamp]).not_to be_nil

    expect(datapoints[:counter][2][:metric]).to eql("timer.testing.five_minute_rate")
    expect(datapoints[:counter][2][:value]).to eql(0.0)
    expect(datapoints[:counter][2][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][2][:timestamp]).not_to be_nil

    expect(datapoints[:counter][3][:metric]).to eql("timer.testing.fifteen_minute_rate")
    expect(datapoints[:counter][3][:value]).to eql(0.0)
    expect(datapoints[:counter][3][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][3][:timestamp]).not_to be_nil

    expect(datapoints[:counter][4][:metric]).to eql("timer.testing.mean_rate")
    expect(datapoints[:counter][4][:value]).not_to be_nil
    expect(datapoints[:counter][4][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][4][:timestamp]).not_to be_nil

    expect(datapoints[:counter][5][:metric]).to eql("timer.testing.min")
    expect(datapoints[:counter][5][:value]).not_to be_nil
    expect(datapoints[:counter][5][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][5][:timestamp]).not_to be_nil

    expect(datapoints[:counter][6][:metric]).to eql("timer.testing.max")
    expect(datapoints[:counter][6][:value]).not_to be_nil
    expect(datapoints[:counter][6][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][6][:timestamp]).not_to be_nil

    expect(datapoints[:counter][7][:metric]).to eql("timer.testing.mean")
    expect(datapoints[:counter][7][:value]).not_to be_nil
    expect(datapoints[:counter][7][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][7][:timestamp]).not_to be_nil

    expect(datapoints[:counter][8][:metric]).to eql("timer.testing.stddev")
    expect(datapoints[:counter][8][:value]).not_to be_nil
    expect(datapoints[:counter][8][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][8][:timestamp]).not_to be_nil

    expect(datapoints[:counter][9][:metric]).to eql("timer.testing.median")
    expect(datapoints[:counter][9][:value]).not_to be_nil
    expect(datapoints[:counter][9][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][9][:timestamp]).not_to be_nil

    expect(datapoints[:counter][10][:metric]).to eql("timer.testing.95th_percentile")
    expect(datapoints[:counter][10][:value]).not_to be_nil
    expect(datapoints[:counter][10][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][10][:timestamp]).not_to be_nil
  end

  it "histogram" do
    @registry.histogram('histogram.testing').update(1.5)
    datapoints = @reporter.get_datapoints
    expect(datapoints[:counter].size).to eql(7)
    expect(datapoints[:counter][0][:metric]).to eql("histogram.testing.count")
    expect(datapoints[:counter][0][:value]).to eql(1)
    expect(datapoints[:counter][0][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][0][:timestamp]).not_to be_nil

    expect(datapoints[:counter][1][:metric]).to eql("histogram.testing.min")
    expect(datapoints[:counter][1][:value]).not_to be_nil
    expect(datapoints[:counter][1][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][1][:timestamp]).not_to be_nil

    expect(datapoints[:counter][2][:metric]).to eql("histogram.testing.max")
    expect(datapoints[:counter][2][:value]).not_to be_nil
    expect(datapoints[:counter][2][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][2][:timestamp]).not_to be_nil

    expect(datapoints[:counter][3][:metric]).to eql("histogram.testing.mean")
    expect(datapoints[:counter][3][:value]).not_to be_nil
    expect(datapoints[:counter][3][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][3][:timestamp]).not_to be_nil

    expect(datapoints[:counter][4][:metric]).to eql("histogram.testing.stddev")
    expect(datapoints[:counter][4][:value]).not_to be_nil
    expect(datapoints[:counter][4][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][4][:timestamp]).not_to be_nil

    expect(datapoints[:counter][5][:metric]).to eql("histogram.testing.median")
    expect(datapoints[:counter][5][:value]).not_to be_nil
    expect(datapoints[:counter][5][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][5][:timestamp]).not_to be_nil

    expect(datapoints[:counter][6][:metric]).to eql("histogram.testing.95th_percentile")
    expect(datapoints[:counter][6][:value]).not_to be_nil
    expect(datapoints[:counter][6][:dimensions]).to include(:env => "test")
    expect(datapoints[:counter][6][:timestamp]).not_to be_nil
  end

  it "gauge" do
    @registry.gauge('gauge.testing') { 123 }
    datapoints = @reporter.get_datapoints
    expect(datapoints[:gauge].size).to eql(1)
    expect(datapoints[:gauge][0][:metric]).to eql("gauge.testing.value")
    expect(datapoints[:gauge][0][:value]).to eql(123)
    expect(datapoints[:gauge][0][:dimensions]).to include(:env => "test")
    expect(datapoints[:gauge][0][:timestamp]).not_to be_nil
  end
end

describe "Rest Client" do
  before(:each) do
    @registry = Metriks::Registry.new
    @reporter = Metriks::SignalFxReporter.new(
      'http://localhost:4242/api/datapoint', 
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
