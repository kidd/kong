local BasePlugin       = require "kong.plugins.base_plugin"
local basic_serializer = require "kong.plugins.log-serializers.basic"
local statsd_logger    = require "kong.plugins.datadog.statsd_logger"


local ngx_log       = ngx.log
local ngx_timer_at  = ngx.timer.at
local string_gsub   = string.gsub
local pairs         = pairs
local string_format = string.format
local NGX_ERR       = ngx.ERR
local inspect =  require'inspect'

-- .init creates an object we should keep along all the run.
prometheus = assert(require "kong.plugins.prometheus.prometheus").init("prometheus_metrics")


local PrometheusHandler    = BasePlugin:extend()
PrometheusHandler.PRIORITY = 10
PrometheusHandler.VERSION = "0.1.0"

function PrometheusHandler:new()
  PrometheusHandler.super.new(self, "prometheus")
  self.prometheus = prometheus
  self.metrics = {}
  -- self.metrics =  initialize_metrics(prometheus) -- how to access the configs?
end

local metrics = {
  status_count = function(api_name, message, metric_config, logger)
  end
}

local function log(premature, conf, message, self)
  if premature then
    return
  end

  local api_name   = string_gsub(message.api.name, "%.", "_")

  local stat_value = {
    request_size     = tonumber(message.request.size),
    response_size    = tonumber(message.response.size),
    latency          = message.latencies.request,
    upstream_latency = message.latencies.proxy,
    kong_latency     = message.latencies.kong,
    request_count    = 1,
  }

  local host = api_name
  local status = message.response.status


  ngx_log(NGX_ERR, inspect(stat_value))

  self.global_metrics.metric_requests:inc(1, {host, status})
  self.global_metrics.upstream_latency:observe(stat_value.upstream_latency, {host})
  self.global_metrics.latency:observe(stat_value.latency, {host})
  self.global_metrics.kong_latency:observe(stat_value.kong_latency, {host})

  self.global_metrics.request_size:observe(stat_value.request_size, {host})
  self.global_metrics.response_size:observe(stat_value.response_size, {host})
end


local function create_metrics(self)
  return {
    metric_requests = self.prometheus:counter("nginx_http_requests_total",
                                              "Number of HTTP requests",
                                              {"host", "status"}),
    request_size = self.prometheus:histogram(
      "nginx_http_request_size",
      "Request size",
      {"host"}),
    response_size = self.prometheus:histogram(
      "nginx_http_response_size",
      "Response size",
      {"host"}),
    latency = self.prometheus:histogram(
      "nginx_http_request_total_duration_seconds",
      "HTTP request total latency",
      {"host"}),
    upstream_latency = self.prometheus:histogram(
      "nginx_http_request_upstream_duration_seconds",
      "HTTP request upstream latency",
      {"host"}),
    kong_latency = self.prometheus:histogram(
      "nginx_http_request_kong_duration_seconds",
      "HTTP request kong latency",
      {"host"}),
    metric_connections = self.prometheus:gauge(
      "nginx_http_connections",
      "Number of HTTP connections",
      {"state"})
  }
end

function PrometheusHandler:log(conf)
  PrometheusHandler.super.log(self)

  -- unmatched apis are nil
  if not ngx.ctx.api then
    return
  end

  local message = basic_serializer.serialize(ngx)

  ngx_log(NGX_ERR, "logging prometheus metrics")

  self.global_metrics = self.global_metrics or create_metrics(self)

  local ok, err = ngx_timer_at(0, log, conf, message, self)
  if not ok then
    ngx_log(NGX_ERR, "failed to create timer: ", err)
  end


  -- local host = ngx.var.host:gsub("^www.", "")
  -- global_metrics.metric_requests:inc(1, {host, ngx.var.status})
  -- global_metrics.metric_latency:observe(ngx.now() - ngx.req.start_time(), {host})

end

return PrometheusHandler
