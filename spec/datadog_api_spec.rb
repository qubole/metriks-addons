##
# Copyright (c) 2015. Qubole Inc
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#    limitations under the License.
##

require 'webmock/rspec'
require 'metriks'
require 'metriks-addons/datadog_reporter'

describe "Smoke test" do
  before(:all) do
    stub_request(:any, "http://localhost:4242")
  end

  before(:each) do
    @registry = Metriks::Registry.new
    @reporter = MetriksAddons::DatadogApiReporter.new(
        "123456789",
        "127.0.0.1",
        [{:env => "test"}],
        { :registry => @registry})
  end

  after(:each) do
    @reporter.stop
    @registry.stop
  end

  it "meter" do
    @registry.meter('meter.testing').mark
    datapoints = @reporter.get_datapoints
    expect(datapoints['counter'].size).to eql(1)
    expect(datapoints['counter']).to have_key("meter.testing.count")
    expect(datapoints['counter']["meter.testing.count"][0][1]).to eql(1)
    expect(datapoints['counter']["meter.testing.count"][0][0]).not_to be_nil
  end

  it "counters" do
    @registry.counter('counter.testing').increment
    datapoints = @reporter.get_datapoints
    expect(datapoints['counter'].size).to eql(1)
    expect(datapoints['counter']).to have_key("counter.testing.count")
    expect(datapoints['counter']["counter.testing.count"][0][1]).to eql(1)
    expect(datapoints['counter']["counter.testing.count"][0][0]).not_to be_nil
  end

  it "timer" do
    @registry.timer('timer.testing').update(1.5)
    datapoints = @reporter.get_datapoints
    expect(datapoints['counter'].size).to eql(1)
    expect(datapoints['gauge'].size).to eql(3)
    expect(datapoints['counter']).to have_key("timer.testing.count")
    expect(datapoints['counter']['timer.testing.count'][0][1]).to eql(1)
    expect(datapoints['counter']['timer.testing.count'][0][0]).not_to be_nil

    expect(datapoints['gauge']).to have_key("timer.testing.min")
    expect(datapoints['gauge']['timer.testing.min'][0][1]).not_to be_nil
    expect(datapoints['gauge']['timer.testing.min'][0][0]).not_to be_nil

    expect(datapoints['gauge']).to have_key("timer.testing.max")
    expect(datapoints['gauge']['timer.testing.max'][0][1]).not_to be_nil
    expect(datapoints['gauge']['timer.testing.max'][0][0]).not_to be_nil

    expect(datapoints['gauge']).to have_key("timer.testing.mean")
    expect(datapoints['gauge']['timer.testing.mean'][0][1]).not_to be_nil
    expect(datapoints['gauge']['timer.testing.mean'][0][0]).not_to be_nil
  end

  it "gauges" do
    @registry.gauge('gauge.testing') { 123 }
    datapoints = @reporter.get_datapoints
    expect(datapoints['gauge'].size).to eql(1)
    expect(datapoints['gauge']).to have_key("gauge.testing.value")
    expect(datapoints['gauge']['gauge.testing.value'][0][1]).to eql(123)
    expect(datapoints['gauge']['gauge.testing.value'][0][0]).not_to be_nil
  end
end