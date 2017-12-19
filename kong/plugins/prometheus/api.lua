ngx.log(ngx.ERR, "evaluating api file")
return {
  ['/metrics'] = {
    GET = function(self)
      ngx.log(ngx.ERR, "getting metrics")
      metric_connections:set(ngx.var.connections_reading, {"reading"})
      metric_connections:set(ngx.var.connections_waiting, {"waiting"})
      metric_connections:set(ngx.var.connections_writing, {"writing"})
      prometheus:collect()

      ngx.exit(ngx.HTTP_OK)
    end

}}
