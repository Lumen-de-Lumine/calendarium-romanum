# Module wrapping the gem's classes
#
# If you hate typing the long module name, see {CR}
module CalendariumRomanum
end

%w(
  version
  i18n_setup
  abstract_date
  rank
  enum
  enums
  errors
  data
  day
  calendar
  perpetual_calendar
  temporale/dates
  temporale/celebration_factory
  temporale/extensions/christ_eternal_priest
  temporale/extensions/thanksgiving_us
  temporale
  sanctorale
  sanctorale_loader
  sanctorale_factory
  transfers
  util
  ordinalizer
).each do |f|
  require_relative File.join('calendarium-romanum', f)
end
