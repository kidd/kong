return {
  no_consumer = true,
--  metric = {type = "string"},
  fields = { -- required field
    prefix = {
      type = "string",
      default = "kong"
    }
  }
}
