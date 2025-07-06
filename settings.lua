local const = require("const")

data:extend({
  {
    type = "string-setting",
    name = const.mod_name .. "-quality-mode",
    setting_type = "runtime-per-user",
    default_value = "any-quality",
    allowed_values = {"any-quality", "matching-quality"},
  }
})
