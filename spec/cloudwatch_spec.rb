require 'webmock/rspec'
require 'metriks'
require 'metriks-addons/cloudwatch_reporter'

describe "Smoke test" do
  before(:each) do
    allow_any_instance_of(AWS::CloudWatch).to receive(:put_metric_data)
    @registry = Metriks::Registry.new
    @reporter = MetriksAddons::CloudWatchReporter.new(
      'DummyDummyDummyDummy',
      "DummyDummyDummyDummyDummyDummyDummyDummy",
      "testingtier",
      {:env =>"test"},
      { :registry => @registry, :batch_size => 3})
  end

  after(:each) do
    @reporter.stop
    @registry.stop
  end

  it "meter" do
    @registry.meter('meter.testing').mark
    datapoints = @reporter.get_datapoints
    expect(datapoints.size).to eql(2)
    expect(datapoints[0][:metric_name]).to eql("meter.testing.count")
    expect(datapoints[0][:value]).to eql(1)
    expect(datapoints[0][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[0][:timestamp]).not_to be_nil
    expect(datapoints[0][:unit]).to eql('Count')

    expect(datapoints[1][:metric_name]).to eql("meter.testing.mean_rate")
    expect(datapoints[1][:value]).not_to be_nil
    expect(datapoints[1][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[1][:timestamp]).not_to be_nil
    expect(datapoints[1][:unit]).to eql('Count/Second')
  end

  it "counter" do
    @registry.counter('counter.testing').increment
    datapoints = @reporter.get_datapoints
    expect(datapoints.size).to eql(1)
    expect(datapoints[0][:metric_name]).to eql("counter.testing.count")
    expect(datapoints[0][:value]).to eql(1)
    expect(datapoints[0][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[0][:timestamp]).not_to be_nil
    expect(datapoints[0][:unit]).to eql('Count')
  end

  it "timer" do
    @registry.timer('timer.testing').update(1.5)
    datapoints = @reporter.get_datapoints
    expect(datapoints.size).to eql(7)
    expect(datapoints[0][:metric_name]).to eql("timer.testing.count")
    expect(datapoints[0][:value]).to eql(1)
    expect(datapoints[0][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[0][:timestamp]).not_to be_nil
    expect(datapoints[0][:unit]).to eql('Count')

    expect(datapoints[1][:metric_name]).to eql("timer.testing.mean_rate")
    expect(datapoints[1][:value]).not_to be_nil
    expect(datapoints[1][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[1][:timestamp]).not_to be_nil
    expect(datapoints[1][:unit]).to eql('Count/Second')

    expect(datapoints[2][:metric_name]).to eql("timer.testing.min")
    expect(datapoints[2][:value]).not_to be_nil
    expect(datapoints[2][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[2][:timestamp]).not_to be_nil
    expect(datapoints[2][:unit]).to eql('Seconds')

    expect(datapoints[3][:metric_name]).to eql("timer.testing.max")
    expect(datapoints[3][:value]).not_to be_nil
    expect(datapoints[3][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[3][:timestamp]).not_to be_nil
    expect(datapoints[3][:unit]).to eql('Seconds')

    expect(datapoints[4][:metric_name]).to eql("timer.testing.mean")
    expect(datapoints[4][:value]).not_to be_nil
    expect(datapoints[4][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[4][:timestamp]).not_to be_nil
    expect(datapoints[4][:unit]).to eql('Seconds')

    expect(datapoints[5][:metric_name]).to eql("timer.testing.stddev")
    expect(datapoints[5][:value]).not_to be_nil
    expect(datapoints[5][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[5][:timestamp]).not_to be_nil
    expect(datapoints[5][:unit]).to eql('Seconds')

    expect(datapoints[6][:metric_name]).to eql("timer.testing.median")
    expect(datapoints[6][:value]).not_to be_nil
    expect(datapoints[6][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[6][:timestamp]).not_to be_nil
    expect(datapoints[6][:unit]).to eql('Seconds')
  end

  it "histogram" do
    @registry.histogram('histogram.testing').update(1.5)
    datapoints = @reporter.get_datapoints
    expect(datapoints.size).to eql(6)
    expect(datapoints[0][:metric_name]).to eql("histogram.testing.count")
    expect(datapoints[0][:value]).to eql(1)
    expect(datapoints[0][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[0][:timestamp]).not_to be_nil
    expect(datapoints[0][:unit]).to eql('Count')

    expect(datapoints[1][:metric_name]).to eql("histogram.testing.min")
    expect(datapoints[1][:value]).not_to be_nil
    expect(datapoints[1][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[1][:timestamp]).not_to be_nil
    expect(datapoints[1][:unit]).to eql('Count')

    expect(datapoints[2][:metric_name]).to eql("histogram.testing.max")
    expect(datapoints[2][:value]).not_to be_nil
    expect(datapoints[2][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[2][:timestamp]).not_to be_nil
    expect(datapoints[2][:unit]).to eql('Count')

    expect(datapoints[3][:metric_name]).to eql("histogram.testing.mean")
    expect(datapoints[3][:value]).not_to be_nil
    expect(datapoints[3][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[3][:timestamp]).not_to be_nil
    expect(datapoints[3][:unit]).to eql('Count')

    expect(datapoints[4][:metric_name]).to eql("histogram.testing.stddev")
    expect(datapoints[4][:value]).not_to be_nil
    expect(datapoints[4][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[4][:timestamp]).not_to be_nil
    expect(datapoints[4][:unit]).to eql('Count')

    expect(datapoints[5][:metric_name]).to eql("histogram.testing.median")
    expect(datapoints[5][:value]).not_to be_nil
    expect(datapoints[5][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[5][:timestamp]).not_to be_nil
    expect(datapoints[5][:unit]).to eql('Count')
  end

  it "gauge" do
    @registry.gauge('gauge.testing') { 123 }
    datapoints = @reporter.get_datapoints
    expect(datapoints.size).to eql(1)
    expect(datapoints[0][:metric_name]).to eql("gauge.testing.value")
    expect(datapoints[0][:value]).to eql(123)
    expect(datapoints[0][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[0][:timestamp]).not_to be_nil
    expect(datapoints[0][:unit]).to eql('Count')
  end
end
