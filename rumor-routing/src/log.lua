log = {}

function get_current_time()
  local date_table = os.date("*t")
  local ms = string.match(tostring(os.clock()), "%d%.(%d+)")
  local hour, minute, second = date_table.hour, date_table.min, date_table.sec
  local year, month, day = date_table.year, date_table.month, date_table.wday
  return string.format("%d:%d:%d:%s", hour, minute, second, ms)
end

function log.initialize_log(id)
  log.file = io.open(id .. "_logs.csv", "a")
  log.file:write("node;message;timestamp", "\n")
  log.file:close()
end

function log.write_log_file(node_id, message)
  log.file = io.open(node_id .. "_logs.csv", "a")
  log.file:write(node_id .. ";" .. message .. ";" .. get_current_time(), "\n")
  log.file:close()
end

return log