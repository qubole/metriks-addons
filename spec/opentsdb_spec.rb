require 'webmock/rspec'
require 'metriks'
require 'metriks/opentsdb_reporter'

describe "Smoke test" do
  before(:all) do
    stub_request(:any, "http://localhost:4242")
  end

  before(:each) do
    @registry = Metriks::Registry.new
    @reporter = Metriks::OpenTSDBReporter.new(
      'http://localhost:4242',
      {:env => "test"},
      { :registry => @registry })
  end

  after(:each) do
    @reporter.stop
    @registry.stop
  end

  it "meter" do
    @registry.meter('meter.testing').mark
    datapoints = @reporter.get_datapoints
    expect(datapoints.size).to eql(5)
    expect(datapoints[0][:metric]).to eql("meter.testing.count")
    expect(datapoints[0][:value]).to eql(1)
    expect(datapoints[0][:tags]).to include(:env => "test")
    expect(datapoints[0][:timestamp]).not_to be_nil

    expect(datapoints[1][:metric]).to eql("meter.testing.one_minute_rate")
    expect(datapoints[1][:value]).not_to be_nil
    expect(datapoints[1][:tags]).to include(:env => "test")
    expect(datapoints[1][:timestamp]).not_to be_nil

    expect(datapoints[2][:metric]).to eql("meter.testing.five_minute_rate")
    expect(datapoints[2][:value]).to eql(0.0)
    expect(datapoints[2][:tags]).to include(:env => "test")
    expect(datapoints[2][:timestamp]).not_to be_nil

    expect(datapoints[3][:metric]).to eql("meter.testing.fifteen_minute_rate")
    expect(datapoints[3][:value]).to eql(0.0)
    expect(datapoints[3][:tags]).to include(:env => "test")
    expect(datapoints[3][:timestamp]).not_to be_nil

    expect(datapoints[4][:metric]).to eql("meter.testing.mean_rate")
    expect(datapoints[4][:value]).not_to be_nil
    expect(datapoints[4][:tags]).to include(:env => "test")
    expect(datapoints[4][:timestamp]).not_to be_nil
  end

  it "counter" do
    @registry.counter('counter.testing').increment
    datapoints = @reporter.get_datapoints
    expect(datapoints.size).to eql(1)
    expect(datapoints[0][:metric]).to eql("counter.testing.count")
    expect(datapoints[0][:value]).to eql(1)
    expect(datapoints[0][:tags]).to include(:env => "test")
    expect(datapoints[0][:timestamp]).not_to be_nil
  end

  it "timer" do
    @registry.timer('timer.testing').update(1.5)
    datapoints = @reporter.get_datapoints
    expect(datapoints.size).to eql(11)
    expect(datapoints[0][:metric]).to eql("timer.testing.count")
    expect(datapoints[0][:value]).to eql(1)
    expect(datapoints[0][:tags]).to include(:env => "test")
    expect(datapoints[0][:timestamp]).not_to be_nil

    expect(datapoints[1][:metric]).to eql("timer.testing.one_minute_rate")
    expect(datapoints[1][:value]).not_to be_nil
    expect(datapoints[1][:tags]).to include(:env => "test")
    expect(datapoints[1][:timestamp]).not_to be_nil

    expect(datapoints[2][:metric]).to eql("timer.testing.five_minute_rate")
    expect(datapoints[2][:value]).to eql(0.0)
    expect(datapoints[2][:tags]).to include(:env => "test")
    expect(datapoints[2][:timestamp]).not_to be_nil

    expect(datapoints[3][:metric]).to eql("timer.testing.fifteen_minute_rate")
    expect(datapoints[3][:value]).to eql(0.0)
    expect(datapoints[3][:tags]).to include(:env => "test")
    expect(datapoints[3][:timestamp]).not_to be_nil

    expect(datapoints[4][:metric]).to eql("timer.testing.mean_rate")
    expect(datapoints[4][:value]).not_to be_nil
    expect(datapoints[4][:tags]).to include(:env => "test")
    expect(datapoints[4][:timestamp]).not_to be_nil

    expect(datapoints[5][:metric]).to eql("timer.testing.min")
    expect(datapoints[5][:value]).not_to be_nil
    expect(datapoints[5][:tags]).to include(:env => "test")
    expect(datapoints[5][:timestamp]).not_to be_nil

    expect(datapoints[6][:metric]).to eql("timer.testing.max")
    expect(datapoints[6][:value]).not_to be_nil
    expect(datapoints[6][:tags]).to include(:env => "test")
    expect(datapoints[6][:timestamp]).not_to be_nil

    expect(datapoints[7][:metric]).to eql("timer.testing.mean")
    expect(datapoints[7][:value]).not_to be_nil
    expect(datapoints[7][:tags]).to include(:env => "test")
    expect(datapoints[7][:timestamp]).not_to be_nil

    expect(datapoints[8][:metric]).to eql("timer.testing.stddev")
    expect(datapoints[8][:value]).not_to be_nil
    expect(datapoints[8][:tags]).to include(:env => "test")
    expect(datapoints[8][:timestamp]).not_to be_nil

    expect(datapoints[9][:metric]).to eql("timer.testing.median")
    expect(datapoints[9][:value]).not_to be_nil
    expect(datapoints[9][:tags]).to include(:env => "test")
    expect(datapoints[9][:timestamp]).not_to be_nil

    expect(datapoints[10][:metric]).to eql("timer.testing.95th_percentile")
    expect(datapoints[10][:value]).not_to be_nil
    expect(datapoints[10][:tags]).to include(:env => "test")
    expect(datapoints[10][:timestamp]).not_to be_nil
  end

  it "histogram" do
    @registry.histogram('histogram.testing').update(1.5)
    datapoints = @reporter.get_datapoints
    expect(datapoints.size).to eql(7)
    expect(datapoints[0][:metric]).to eql("histogram.testing.count")
    expect(datapoints[0][:value]).to eql(1)
    expect(datapoints[0][:tags]).to include(:env => "test")
    expect(datapoints[0][:timestamp]).not_to be_nil

    expect(datapoints[1][:metric]).to eql("histogram.testing.min")
    expect(datapoints[1][:value]).not_to be_nil
    expect(datapoints[1][:tags]).to include(:env => "test")
    expect(datapoints[1][:timestamp]).not_to be_nil

    expect(datapoints[2][:metric]).to eql("histogram.testing.max")
    expect(datapoints[2][:value]).not_to be_nil
    expect(datapoints[2][:tags]).to include(:env => "test")
    expect(datapoints[2][:timestamp]).not_to be_nil

    expect(datapoints[3][:metric]).to eql("histogram.testing.mean")
    expect(datapoints[3][:value]).not_to be_nil
    expect(datapoints[3][:tags]).to include(:env => "test")
    expect(datapoints[3][:timestamp]).not_to be_nil

    expect(datapoints[4][:metric]).to eql("histogram.testing.stddev")
    expect(datapoints[4][:value]).not_to be_nil
    expect(datapoints[4][:tags]).to include(:env => "test")
    expect(datapoints[4][:timestamp]).not_to be_nil

    expect(datapoints[5][:metric]).to eql("histogram.testing.median")
    expect(datapoints[5][:value]).not_to be_nil
    expect(datapoints[5][:tags]).to include(:env => "test")
    expect(datapoints[5][:timestamp]).not_to be_nil

    expect(datapoints[6][:metric]).to eql("histogram.testing.95th_percentile")
    expect(datapoints[6][:value]).not_to be_nil
    expect(datapoints[6][:tags]).to include(:env => "test")
    expect(datapoints[6][:timestamp]).not_to be_nil
  end

  it "gauge" do
    @registry.gauge('gauge.testing') { 123 }
    datapoints = @reporter.get_datapoints
    expect(datapoints.size).to eql(1)
    expect(datapoints[0][:metric]).to eql("gauge.testing.value")
    expect(datapoints[0][:value]).to eql(123)
    expect(datapoints[0][:tags]).to include(:env => "test")
    expect(datapoints[0][:timestamp]).not_to be_nil
  end
end

describe "Rest Client" do
  before(:each) do
    @registry = Metriks::Registry.new
    @reporter = Metriks::OpenTSDBReporter.new(
      'http://localhost:4242',
      {:env => "test"},
      { :registry => @registry, :batch_size => 3})
    stub_request(:post, "http://localhost:4242/api/put").
      with(:body => /^\[.*\]$/).
      to_return(:status => 200, :body => "", :headers => {})
  end

  it "Send a single metric" do
    @registry.counter('counter.testing').increment
    @reporter.submit @reporter.get_datapoints
    #TODO Also check body
    body = [{
      :metric => "counter.testing",
      :timestamp => 1438446900,
      :value => 1,
      :tags => { :env => "test"}}
    ]
    expect(a_request(:post, "http://localhost:4242/api/put")).to have_been_made
  end

  it "Send a three metric" do
    for i in 0..2 do
      @registry.counter("counter.testing.#{i}").increment
    end
    @reporter.submit @reporter.get_datapoints
    expect(a_request(:post, "http://localhost:4242/api/put")).to have_been_made
  end

  it "Send a four metric" do
    for i in 0..3 do
      @registry.counter("counter.testing.#{i}").increment
    end
    @reporter.submit @reporter.get_datapoints
    expect(a_request(:post, "http://localhost:4242/api/put")).to have_been_made.times(2)
  end

  it "Send a five metric" do
    for i in 0..4 do
      @registry.counter("counter.testing.#{i}").increment
    end
    @reporter.submit @reporter.get_datapoints
    expect(a_request(:post, "http://localhost:4242/api/put")).to have_been_made.times(2)
  end

  it "Send a six metric" do
    for i in 0..5 do
      @registry.counter("counter.testing.#{i}").increment
    end
    @reporter.submit @reporter.get_datapoints
    expect(a_request(:post, "http://localhost:4242/api/put")).to have_been_made.times(2)
  end

  it "Send a seven metric" do
    for i in 0..7 do
      @registry.counter("counter.testing.#{i}").increment
    end
    @reporter.submit @reporter.get_datapoints
    expect(a_request(:post, "http://localhost:4242/api/put")).to have_been_made.times(3)
  end
end
