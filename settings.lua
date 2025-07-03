local constants = require("constants")

data:extend({
  {
    type = "string-setting",
    name = constants.mod_name .. "-quality-mode",
    setting_type = "runtime-per-user",
    default_value = "any-quality",
    allowed_values = {"any-quality", "matching-quality"},
    order = "b[filtered-deconstruction]-a[quality-mode]",
  }
})
