local BasePlugin       = require "kong.plugins.base_plugin"
local basic_serializer = require "kong.plugins.log-serializers.basic"
local statsd_logger    = require "kong.plugins.datadog.statsd_logger"

local PrometheusHandler    = BasePlugin:extend()
PrometheusHandler.PRIORITY = 10
PrometheusHandler.VERSION = "0.1.0"

function PrometheusHandler:new()
  PrometheusHandler.super.new(self, "prometheus")
end

function PrometheusHandler:log(conf)
  PrometheusHandler.super.log(self)
end
