-- local default_metrics = {
--   {
--     name        = "request_count",
--     stat_type   = "counter",
--     sample_rate = 1,
--     tags        = {"app:kong"}
--   }
-- }

local function check_schema(value)
  return true
end


return {
  no_consumer = true,
--  metric = {type = "string"},
  fields = { -- required field
    metrics = {
      required = true,
      type = "array",
      default = default_metrics,
      func = check_schema,
    },
    prefix = {
      type = "string",
      default = "kong"
    }
  }
}
