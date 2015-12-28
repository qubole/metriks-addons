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
require 'signalfx'
require_relative 'base_reporter'

module MetriksAddons
  class SignalFxReporter < BaseReporter
    attr_accessor :client, :prefix, :source, :data, :tags, :logger

    def initialize(token, tags, options = {})
      super(options)
      @x_sf_token = token
      @tags = tags

      @prefix = options[:prefix]
      @source = options[:source]

      @batch_size   = options[:batch_size] || 50

      @client = SignalFx.new @x_sf_token, batch_size: @batch_size
    end

    def submit(datapoints)
      return if datapoints.empty?

      log "debug", "Datapoints for SignalFx: #{datapoints.inspect}"
      response = @client.send(counters: datapoints[:counters], gauges: datapoints[:gauges])
      log "debug", "Sent #{datapoints.size} metrics to SignalFX"
      log "debug", "Response is: #{response}"
    end

    def get_datapoints
      time = @time_tracker.now_floored

      datapoints = {}
      counter = []
      gauge = []
      log "debug", "Resgistry: #{@registry}"
      @registry.each do |name, metric|
        next if name.nil? || name.empty?
        name = name.to_s.gsub(/ +/, '_')
        if @prefix
          name = "#{@prefix}.#{name}"
        end

        case metric
        when Metriks::Meter
          counter |= create_datapoints name, metric, time, [
            :count
          ]
        when Metriks::Counter
          counter |= create_datapoints name, metric, time, [
            :count
          ]
        when Metriks::Gauge
          gauge |= create_datapoints name, metric, time, [
            :value
          ]
        when Metriks::Timer
          counter |= create_datapoints name, metric, time, [
            :count
          ]
          gauge |= create_datapoints name, metric, time, [
            :min, :max, :mean
          ]
        end
      end

      datapoints[:counters] = counter if counter.any?
      datapoints[:gauges] = gauge if gauge.any?
      datapoints
    end

    def create_datapoints(base_name, metric, time, keys, snapshot_keys = [])
      datapoints = []
      keys.flatten.each do |key|
        name = key.to_s.gsub(/^get_/, '')
        datapoints << {
          :metric => "#{base_name}.#{name}",
          :timestamp => time*1000,
          :value => metric.send(key),
          :dimensions => @tags
        }
      end

      unless snapshot_keys.empty?
        snapshot = metric.snapshot
        snapshot_keys.flatten.each do |key|
          name = key.to_s.gsub(/^get_/, '')
          datapoints << {
            :metric => "#{base_name}.#{name}",
            :timestamp => time*1000,
            :value => snapshot.send(key),
            :dimensions => @tags
          }
        end
      end
      datapoints
    end
  end
end
