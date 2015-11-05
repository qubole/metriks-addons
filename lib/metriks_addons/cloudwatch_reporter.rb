require 'metriks/time_tracker'
require 'logger'
require 'aws'
require 'time'
require 'metriks_addons/base_reporter'

module MetriksAddons
  class CloudWatchReporter < BaseReporter
    attr_accessor :prefix, :source, :cw, :tags, :logger

    def initialize(access_key, secret_key, namespace, tags, options = {})
      super(options)
      @cw = AWS::CloudWatch.new(:access_key_id => access_key, :secret_access_key => secret_key)
      @namespace = namespace
      @dimensions = get_dimensions(tags)

      @prefix = options[:prefix]
      @source = options[:source]

      @batch_size   = options[:batch_size] || 50
    end

    def submit(datapoints)
      return if datapoints.empty?
      datapoints.each do |datapoint|
        response = @cw.put_metric_data({:namespace => @namespace, :metric_data => [datapoint]})
      end
      log "info", "Sent #{datapoints.size} metrics to CloudWatch"
    end

    def get_datapoints
      time = Time.at(@time_tracker.now_floored).iso8601

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
            :count, :mean_rate
          ], [
            'Count', 'Count/Second'
          ]
        when Metriks::Counter
          datapoints |= create_datapoints name, metric, time, [
            :count
          ], [
            'Count'
          ]
        when Metriks::Gauge
          datapoints |= create_datapoints name, metric, time, [
            :value
          ], [
            'Count'
          ]
        when Metriks::Timer
          datapoints |= create_datapoints name, metric, time, [
            :count, :mean_rate, :min, :max, :mean, :stddev
          ], [
            'Count', 'Count/Second', 'Seconds', 'Seconds',
            'Seconds', 'Seconds'
          ], [
            :median
          ], [
            'Seconds'
          ]
        when Metriks::Histogram
          datapoints |= create_datapoints name, metric, time, [
            :count, :min, :max, :mean, :stddev
          ], [
            'Count', 'Count', 'Count', 'Count',
            'Count'
          ], [
            :median
          ], [
            'Count'
          ]
        end
      end
      datapoints
    end

    def create_datapoints(base_name, metric, time, keys, keys_unit, snapshot_keys = [], snapshot_keys_unit = [])
      datapoints = []

      keys.flatten.zip(keys_unit.flatten).each do |key, key_unit|
        name = key.to_s.gsub(/^get_/, '')
        datapoints << {
          :metric_name => "#{base_name}.#{name}",
          :timestamp => time,
          :value => metric.send(key),
          :dimensions => @dimensions,
          :unit => key_unit
        }
      end

      unless snapshot_keys.empty?
        snapshot = metric.snapshot
        snapshot_keys.flatten.zip(snapshot_keys_unit.flatten).each do |key, key_unit|
          name = key.to_s.gsub(/^get_/, '')
          datapoints << {
            :metric_name => "#{base_name}.#{name}",
            :timestamp => time,
            :value => snapshot.send(key),
            :dimensions => @dimensions,
            :unit => key_unit
          }
        end
      end
      datapoints
    end

    def get_dimensions(tags)
      dimensions =[]
      tags.each do |name, value|
        dimensions << {
          :name => "#{name}",
          :value => value
        }
      end
      dimensions
    end
  end
end
