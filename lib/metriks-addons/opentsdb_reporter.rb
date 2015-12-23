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
require 'rest-client'
require 'logger'
require_relative 'base_reporter'

module MetriksAddons
  class OpenTSDBReporter < BaseReporter
    attr_accessor :prefix, :source, :data, :hostname, :tags, :logger

    def initialize(h, t, options = {})
      super(options)
      @hostname = h
      @tags = t

      @prefix = options[:prefix]
      @source = options[:source]

      @batch_size   = options[:batch_size] || 50

      if not @logger.nil?
        RestClient.log =
          Object.new.tap do |proxy|
            def proxy.<<(message)
              Rails.logger.debug message
            end
          end
      end
    end

    def submit(datapoints)
      return if datapoints.empty?

      index = 0
      length = @batch_size
      while index < datapoints.size
        to_send = nil
        if datapoints.size < (index + length)
          length = datapoints.size - index
        else
          length = @batch_size
        end
        jsonstr = datapoints[index, length].to_json
        RestClient.post "#{@hostname}/api/put",
          jsonstr,
          :content_type => :json, :accept => :json
        log "debug", "Sent #{length} metrics from #{index}"
        index += length
      end
      log "info", "Sent #{datapoints.size} metrics to OpenTSDB"
    end

    def get_datapoints
      time = @time_tracker.now_floored

      datapoints = []
      @registry.each do |name, metric|
        next if name.nil? || name.empty?
        name = name.to_s.gsub(/ +/, '_')
        if @prefix
          name = "#{@prefix}.#{name}"
        end

        case metric
        when Metriks::Meter
          datapoints |= create_datapoints name, metric, time, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate
          ]
        when Metriks::Counter
          datapoints |= create_datapoints name, metric, time, [
            :count
          ]
        when Metriks::Gauge
          datapoints |= create_datapoints name, metric, time, [
            :value
          ]
        when Metriks::UtilizationTimer
          datapoints |= create_datapoints name, metric, time, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev,
            :one_minute_utilization, :five_minute_utilization,
            :fifteen_minute_utilization, :mean_utilization,
          ], [
            :median, :get_95th_percentile
          ]

          when Metriks::Timer
          datapoints |= create_datapoints name, metric, time, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
          when Metriks::Histogram
          datapoints |= create_datapoints name, metric, time, [
            :count, :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
        end
      end
      datapoints
    end

    def create_datapoints(base_name, metric, time, keys, snapshot_keys = [])
      datapoints = []
      keys.flatten.each do |key|
        name = key.to_s.gsub(/^get_/, '')
        datapoints << {
          :metric => "#{base_name}.#{name}",
          :timestamp => time,
          :value => metric.send(key),
          :tags => @tags
        }
      end

      unless snapshot_keys.empty?
        snapshot = metric.snapshot
        snapshot_keys.flatten.each do |key|
          name = key.to_s.gsub(/^get_/, '')
          datapoints << {
            :metric => "#{base_name}.#{name}",
            :timestamp => time,
            :value => snapshot.send(key),
            :tags => @tags
          }
        end
      end
      datapoints
    end
  end
end
