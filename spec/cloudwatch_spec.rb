require 'webmock/rspec'
require 'metriks'
require 'metriks_addons/cloudwatch_reporter'

describe "Smoke test" do
  before(:each) do
    AWS::CloudWatch.any_instance.stub(:put_metric_data)
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
    expect(datapoints.size).to eql(5)
    expect(datapoints[0][:metric_name]).to eql("meter.testing.count")
    expect(datapoints[0][:value]).to eql(1)
    expect(datapoints[0][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[0][:timestamp]).not_to be_nil
    expect(datapoints[0][:unit]).to eql('Count')

    expect(datapoints[1][:metric_name]).to eql("meter.testing.one_minute_rate")
    expect(datapoints[1][:value]).not_to be_nil
    expect(datapoints[1][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[1][:timestamp]).not_to be_nil
    expect(datapoints[1][:unit]).to eql('Count/Second')

    expect(datapoints[2][:metric_name]).to eql("meter.testing.five_minute_rate")
    expect(datapoints[2][:value]).to eql(0.0)
    expect(datapoints[2][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[2][:timestamp]).not_to be_nil
    expect(datapoints[2][:unit]).to eql('Count/Second')

    expect(datapoints[3][:metric_name]).to eql("meter.testing.fifteen_minute_rate")
    expect(datapoints[3][:value]).to eql(0.0)
    expect(datapoints[3][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[3][:timestamp]).not_to be_nil
    expect(datapoints[3][:unit]).to eql('Count/Second')

    expect(datapoints[4][:metric_name]).to eql("meter.testing.mean_rate")
    expect(datapoints[4][:value]).not_to be_nil
    expect(datapoints[4][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[4][:timestamp]).not_to be_nil
    expect(datapoints[4][:unit]).to eql('Count/Second')
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
    expect(datapoints.size).to eql(11)
    expect(datapoints[0][:metric_name]).to eql("timer.testing.count")
    expect(datapoints[0][:value]).to eql(1)
    expect(datapoints[0][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[0][:timestamp]).not_to be_nil
    expect(datapoints[0][:unit]).to eql('Count')

    expect(datapoints[1][:metric_name]).to eql("timer.testing.one_minute_rate")
    expect(datapoints[1][:value]).not_to be_nil
    expect(datapoints[1][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[1][:timestamp]).not_to be_nil
    expect(datapoints[1][:unit]).to eql('Count/Second')

    expect(datapoints[2][:metric_name]).to eql("timer.testing.five_minute_rate")
    expect(datapoints[2][:value]).to eql(0.0)
    expect(datapoints[2][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[2][:timestamp]).not_to be_nil
    expect(datapoints[2][:unit]).to eql('Count/Second')

    expect(datapoints[3][:metric_name]).to eql("timer.testing.fifteen_minute_rate")
    expect(datapoints[3][:value]).to eql(0.0)
    expect(datapoints[3][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[3][:timestamp]).not_to be_nil
    expect(datapoints[3][:unit]).to eql('Count/Second')

    expect(datapoints[4][:metric_name]).to eql("timer.testing.mean_rate")
    expect(datapoints[4][:value]).not_to be_nil
    expect(datapoints[4][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[4][:timestamp]).not_to be_nil
    expect(datapoints[4][:unit]).to eql('Count/Second')

    expect(datapoints[5][:metric_name]).to eql("timer.testing.min")
    expect(datapoints[5][:value]).not_to be_nil
    expect(datapoints[5][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[5][:timestamp]).not_to be_nil
    expect(datapoints[5][:unit]).to eql('Seconds')

    expect(datapoints[6][:metric_name]).to eql("timer.testing.max")
    expect(datapoints[6][:value]).not_to be_nil
    expect(datapoints[6][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[6][:timestamp]).not_to be_nil
    expect(datapoints[6][:unit]).to eql('Seconds')

    expect(datapoints[7][:metric_name]).to eql("timer.testing.mean")
    expect(datapoints[7][:value]).not_to be_nil
    expect(datapoints[7][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[7][:timestamp]).not_to be_nil
    expect(datapoints[7][:unit]).to eql('Seconds')

    expect(datapoints[8][:metric_name]).to eql("timer.testing.stddev")
    expect(datapoints[8][:value]).not_to be_nil
    expect(datapoints[8][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[8][:timestamp]).not_to be_nil
    expect(datapoints[8][:unit]).to eql('Seconds')

    expect(datapoints[9][:metric_name]).to eql("timer.testing.median")
    expect(datapoints[9][:value]).not_to be_nil
    expect(datapoints[9][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[9][:timestamp]).not_to be_nil
    expect(datapoints[9][:unit]).to eql('Seconds')

    expect(datapoints[10][:metric_name]).to eql("timer.testing.95th_percentile")
    expect(datapoints[10][:value]).not_to be_nil
    expect(datapoints[10][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[10][:timestamp]).not_to be_nil
    expect(datapoints[10][:unit]).to eql('Seconds')
  end

  it "histogram" do
    @registry.histogram('histogram.testing').update(1.5)
    datapoints = @reporter.get_datapoints
    expect(datapoints.size).to eql(7)
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

    expect(datapoints[6][:metric_name]).to eql("histogram.testing.95th_percentile")
    expect(datapoints[6][:value]).not_to be_nil
    expect(datapoints[6][:dimensions]).to include({:name => "env", :value => "test"})
    expect(datapoints[6][:timestamp]).not_to be_nil
    expect(datapoints[6][:unit]).to eql('Count')
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
