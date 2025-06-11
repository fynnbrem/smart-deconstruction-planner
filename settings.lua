data:extend {
  {
    type = "int-setting",
    name = "personal-trains-pickup-on-arrival-range",
    setting_type = "runtime-per-user",
    default_value = 10,
    minimum_value = 0,

    localised_name = { "setting-name.personal-trains-pickup-on-arrival-range" },
    localised_description = { "setting-description.personal-trains-pickup-on-arrival-range" },

    order = "a[arrival]-a",
  },
  {
    type = "bool-setting",
    name = "personal-trains-eject-on-arrival",
    setting_type = "runtime-per-user",
    default_value = true,

    localised_name = { "setting-name.personal-trains-eject-on-arrival" },
    localised_description = { "setting-description.personal-trains-eject-on-arrival" },

    order = "a[arrival]-b",
  },
  {
    type = "bool-setting",
    name = "personal-trains-manual-on-arrival",
    setting_type = "runtime-per-user",
    default_value = false,

    localised_name = { "setting-name.personal-trains-manual-on-arrival" },

    order = "a[arrival]-c",
  },
  {
    type = "bool-setting",
    name = "personal-trains-open-schedule-on-enter",
    setting_type = "runtime-per-user",
    default_value = true,

    localised_name = { "setting-name.personal-trains-open-schedule-on-enter" },

    order = "b[enter]-a",
  },
  {
    type = "bool-setting",
    name = "personal-trains-clear-other-temp-stations",
    setting_type = "runtime-per-user",
    default_value = true,

    localised_name = { "setting-name.personal-trains-clear-other-temp-stations" },
    localised_description = { "setting-description.personal-trains-clear-other-temp-stations" },

    order = "c[schedule]-a",
  }
}