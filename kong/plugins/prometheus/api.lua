return {
  ['/metrics'] = {
    GET = function(self, dao_factory, helpers)
      ngx.log(ngx.DEBUG, "getting prometheus metrics")

      -- no access to 'global' global_metrics initialized in handler.lua
      --
      -- global_metrics.metric_connections:set(ngx.var.connections_reading, {"reading"})
      -- global_metrics.metric_connections:set(ngx.var.connections_waiting, {"waiting"})
      -- global_metrics.metric_connections:set(ngx.var.connections_writing, {"writing"})
      prometheus:collect()

      ngx.exit(ngx.HTTP_OK)
    end

}}
