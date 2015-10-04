require 'metriks/time_tracker'
require 'rest-client'
require 'logger'
require 'metriks/base_reporter'

module Metriks
  class SignalFxReporter < Metriks::BaseReporter
    attr_accessor :prefix, :source, :data, :hostname, :tags, :logger

    def initialize(h, token, id, tags, options = {})
      super(options)
      @hostname = h
      @x_sf_token = token
      @orgid = id
      @tags = tags

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

      jsonstr = datapoints.to_json
      log "debug", "Json for SignalFx: #{jsonstr}"
      response  = RestClient.post "#{@hostname}?orgid=#{@orgid}",
						        jsonstr,
						        :content_type => :json, :accept => :json, :'X-SF-TOKEN' => @x_sf_token
      log "info", "Sent #{datapoints.size} metrics to SignalFX"
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
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate
          ]
        when Metriks::Counter
          counter |= create_datapoints name, metric, time, [
            :count
          ]
        when Metriks::Gauge
          gauge |= create_datapoints name, metric, time, [
            :value
          ]
        when Metriks::UtilizationTimer
          counter |= create_datapoints name, metric, time, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev,
            :one_minute_utilization, :five_minute_utilization,
            :fifteen_minute_utilization, :mean_utilization,
          ], [
            :median, :get_95th_percentile
          ]

          when Metriks::Timer
          counter |= create_datapoints name, metric, time, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
          when Metriks::Histogram
          counter |= create_datapoints name, metric, time, [
            :count, :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
        end
      end

      datapoints[:counter] = counter if counter.any?
      datapoints[:gauge] = gauge if gauge.any?

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
