local function short_metric_name(full_name)
  local labels_start, _ = full_name:find("{")
  if not labels_start then
    -- no labels
    return full_name
  end
  local suffix_idx, _ = full_name:find("_bucket{")
  if suffix_idx and full_name:find("le=") then
    -- this is a histogram metric
    return full_name:sub(1, suffix_idx - 1)
  end
  -- this is not a histogram metric
  return full_name:sub(1, labels_start - 1)
end

function func_collect()
  local dict = ngx.shared['prometheus_metrics']
  local keys = dict:get_keys(0)
  local prefix = ''

  table.sort(keys)

  ngx.header.content_type = "text/plain"
  local seen_metrics = {}
  local output = {}
  for _, key in ipairs(keys) do
    local value, err = dict:get(key)
    if value then
      local short_name = short_metric_name(key)
      if not seen_metrics[short_name] then
        seen_metrics[short_name] = true
      end
      -- Replace "Inf" with "+Inf" in each metric's last bucket 'le' label.
      if key:find('le="Inf"', 1, true) then
        key = key:gsub('le="Inf"', 'le="+Inf"')
      end
      table.insert(output, string.format("%s%s %s\n", prefix, key, value))
    else
      self:log_error("Error getting '", key, "': ", err)
    end
  end
  ngx.print(output)
end

return {
  ['/metrics'] = {
    GET = function(self, dao_factory, helpers)

      local singletons = require "kong.singletons"

      local inspect =  require'inspect'
      -- ngx.log(ngx.DEBUG, "getting prometheus metrics")

      -- ngx.log(ngx.DEBUG, inspect(singletons.loaded_plugins))
        -- local plugins_iterator = require "kong.core.plugins_iterator"

        -- for plugin, plugin_conf in plugins_iterator(singletons.loaded_plugins, true) do
        --   ngx.log(ngx.DEBUG, inspect(plugin))
        -- end

      -- no access to 'global' global_metrics initialized in handler.lua
      --
      -- global_metrics.metric_connections:set(ngx.var.connections_reading, {"reading"})
      -- global_metrics.metric_connections:set(ngx.var.connections_waiting, {"waiting"})
      -- global_metrics.metric_connections:set(ngx.var.connections_writing, {"writing"})
      func_collect()

      ngx.exit(ngx.HTTP_OK)
    end

}}
