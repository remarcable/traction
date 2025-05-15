module HabitsHelper
  STATUS_ICONS = {
    completed: [ "check", "green" ],
    failed: [ "x-mark", "red" ],
    skipped: [ "forward", "yellow" ],
    pending: [ nil, "slate" ]
  }.freeze

  def entry_status_icon_and_color(entry)
    STATUS_ICONS[entry.status.to_sym] || STATUS_ICONS[:pending]
  end
end
