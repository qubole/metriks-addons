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

require 'metriks/time_tracker'
require 'logger'
require 'dogapi'
require_relative 'base_reporter'

module MetriksAddons
  class DatadogApiReporter < BaseReporter
    attr_accessor :client, :prefix, :source, :tags, :logger

    def initialize(key, host_name, tags, options = {})
      super(options)
      @key = key
      @tags = tags

      @prefix = options[:prefix]
      @client = Dogapi::Client.new(key)
    end

    def submit(datapoints)
      return if datapoints.empty?

      log "debug", "Datapoints for Datadog: #{datapoints.inspect}"
      size = {}
      response = @client.batch_metrics do
        datapoints.each do |type, data|
          size[type] = 0
          data.each do |metric_name, points|
            size[type] += points.size
            if type == 'counter'
              @client.emit_points(metric_name, points, :type => 'counter', :tags => @tags)
            else
              @client.emit_points(metric_name, points, :tags => @tags)
            end
          end
        end
      end

      log "debug", "Sent #{datapoints.size} metrics to Datadog"
      log "debug", "Response is: #{response}"
    end

    def get_datapoints
      seconds = @time_tracker.now_floored
      time = Time.at(seconds)

      datapoints = {}
      counter = {}
      gauge = {}
      log "debug", "Registry: #{@registry}"
      @registry.each do |name, metric|
        next if name.nil? || name.empty?
        name = name.to_s.gsub(/ +/, '_')
        if @prefix
          name = "#{@prefix}.#{name}"
        end

        case metric
          when Metriks::Meter
            counter = counter.merge(create_datapoints name, metric, time, [
                                                 :count
                                             ])
          when Metriks::Counter
            counter = counter.merge(create_datapoints name, metric, time, [
                                                 :count
                                             ])
          when Metriks::Gauge
            gauge = gauge.merge(create_datapoints name, metric, time, [
                                               :value
                                           ])
          when Metriks::Timer
            counter = counter.merge(create_datapoints name, metric, time, [
                                                 :count
                                             ])
            gauge = gauge.merge(create_datapoints name, metric, time, [
                                               :min, :max, :mean
                                           ])
        end
      end

      datapoints['counter'] = counter if counter.any?
      datapoints['gauge'] = gauge if gauge.any?
      datapoints
    end

    def create_datapoints(base_name, metric, time, keys, snapshot_keys = [])
      datapoints = {}

      keys.flatten.each do |key|
        name = key.to_s.gsub(/^get_/, '')
        metric_name = "#{base_name}.#{name}"
        value = metric.send(key)
        datapoints[metric_name] = [[time, value]]
      end

      unless snapshot_keys.empty?
        snapshot = metric.snapshot
        snapshot_keys.flatten.each do |key|
          name = key.to_s.gsub(/^get_/, '')
          metric_name = "#{base_name}.#{name}"
          value = snapshot.send(key)
          datapoints[metric_name] = [[time, value]]
        end
      end
      datapoints
    end
  end
end
