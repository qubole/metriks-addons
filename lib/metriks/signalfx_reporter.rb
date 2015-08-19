require 'metriks/time_tracker'
require 'rest-client'
require 'logger'

module Metriks
  class SignalFxReporter
    attr_accessor :prefix, :source, :data, :hostname, :tags, :logger

    def initialize(h, token, id, tags, options = {})
      @hostname = h
      @x_sf_token = token
      @orgid = id
      @tags = tags

      @prefix = options[:prefix]
      @source = options[:source]

      @logger       = options[:logger] || nil
      @batch_size   = options[:batch_size] || 50
      @registry     = options[:registry] || Metriks::Registry.default
      @interval     = options[:interval] || 60
      @time_tracker = Metriks::TimeTracker.new(@interval)
      @on_error     = options[:on_error] || proc { |ex| }

      if options[:percentiles]
        @percentiles = options[:percentiles]
      else
        @percentiles = [ 0.95, 0.99]
      end

      if not @logger.nil?
        RestClient.log =
          Object.new.tap do |proxy|
            def proxy.<<(message)
              Rails.logger.info message
            end
          end
      end
      @mutex = Mutex.new
      @running = false
    end

    def log(level, msg)
      if !@logger.nil?
        @logger.send level, msg
      end
    end

    def start
      if @thread && @thread.alive?
        return
      end

      @running = true
      @thread = Thread.new do
        while @running
          @time_tracker.sleep

          Thread.new do
            flush
          end
        end
      end
    end

    def stop
      @running = false

      if @thread
        @thread.join
        @thread = nil
      end
    end

    def restart
      stop
      start
    end

    def flush
      begin
        @mutex.synchronize do
          log "debug", "Flushing metrics"
          submit get_datapoints
        end
      rescue Exception => ex
        log "error",ex.message
        @on_error[ex] rescue nil
      end
    end

    def submit(datapoints)
      return if datapoints.empty?

      jsonstr = datapoints.to_json
      log "info", jsonstr
      response  = RestClient.post "#{@hostname}?orgid=#{@orgid}",
						        jsonstr,
						        :content_type => :json, :accept => :json, :'X-SF-TOKEN' => @x_sf_token
      log "info", "Sent #{datapoints.size} metrics"
    end

    def get_datapoints
      time = @time_tracker.now_floored

      datapoints = {}
      counter = []
      gauge = []
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
          :timestamp => time,
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
            :timestamp => time,
            :value => snapshot.send(key),
            :dimensions => @tags
          }
        end
      end
      datapoints
    end
  end
end
