local vim = vim

local debug_mode = false;

local function tprint (tbl, indent)
  if not type(tbl) == "table" then
    return tostring(tbl)
  end
  if tbl == nil then return "nil" end
  if not indent then indent = 0 end
  local res = ""
  for k, v in pairs(tbl) do
    local formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      res = res..formatting..tprint(v, indent+1).."\n"
    elseif type(v) == 'boolean' then
      res = res..formatting..tostring(v).."\n"
    elseif type(v) == 'function' then
      res = res..formatting.." (func)\n"
    else
      res = res..formatting..v.."\n"
    end
  end
  return res
end

local function search(pattern)
    -- Use the search function to find the first match
    local found_pos = vim.fn.search(pattern, 'b')

    if found_pos ~= 0 then
        -- Get the line number and column of the found position
        local line = vim.fn.line('.')
        local col = vim.fn.col('.')

        -- print_search_groups();

        return { line = line, col = col }
    else
        return nil  -- No match found
    end
end

local function substr(line_number, start_col, length)
    -- Get the lines from the buffer
    local lines = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, true)

    if #lines == 0 then
        return nil  -- No lines found
    end

    local line = lines[1]  -- Get the specified line

    -- Ensure start_col is within the bounds of the line
    if start_col > #line then
        return nil  -- Start column is out of bounds
    end

    -- Get the substring based on start column and length
    local substring = line:sub(start_col, start_col + length - 1)
    return substring
end

local function WikiScriptsFillBuffers ()

  local starting_pos = vim.fn.getpos('.')
  local curr_buffer = vim.api.nvim_get_current_buf();

  local t_search = [[\*\*\(\d\d:\d\d\)\*\*]]
  local w_search = [[\*\*w\d\d\{0,1} \(Mon\|Tue\|Wed\|Thu\|\Fri\|Sat\|Sun\)\{0,1} \{0,1}\(\d\d\.\d\d\.\d\d\d\d\)\*\*]]

  local time_line = search(t_search);
  local time = substr(time_line.line, time_line.col + 2, 5)

  local week_line = search(w_search);
  local week = substr(week_line.line, week_line.col + 2, 18);

  local path = '/'..vim.fn.expand("%")

  -- vim.api.nvim_buf_get_name(curr_buffer)
  
  local url = string.format('[%s %s](%s#%s#%s)', week, time, path, week, time);

  vim.fn.setreg('n', url)
  vim.fn.setreg('t', time)
  vim.fn.setreg('w', week)
  vim.fn.setreg('s', path)

  vim.fn.setpos('.', starting_pos)
end


local day_line_pattern = [[([%d.]+)h[ ]*- ([%w%s+]+)%( [ ]?(%d+:%d+) %- [ ]?(%d+:%d+) %)]];
local time_pattern = [[([%d]+):([%d]+)]];
local terminator = [[====]];

local function updateTime(time, shift, has_half)
  local _, _, hours, minutes = time:find(time_pattern);
  hours = hours + shift;
  if hours > 23 then
    hours = hours - 24
  end
  if hours < 0 then
    hours = 24 + hours
  end
  if has_half then
    if minutes == '30' then
      minutes = '00';
      hours = hours + 1;
    else
      minutes = '30';
    end
  end
  local space = hours < 10 and ' ' or '';
  return string.format('%s%s:%s', space, hours, minutes)
end;

local function updateDayLine(line, prev_end)
  local error_msg = '';
  local _, _, interval_str, slot, starting_time, ending_time = line:find(day_line_pattern)

  local has_decimal = false;
  if interval_str ~= nil then has_decimal = interval_str:find("%.") end;

  local interval = 0;
  if interval_str ~= nil then interval = math.floor(tonumber(interval_str)) end;

  local _, _, shift_hours, shift_minutes = prev_end:find(time_pattern);
  local _, _, start_hours, start_minutes = starting_time:find(time_pattern);
  local _, _, end_hours, end_minutes = ending_time:find(time_pattern);

  local shift = shift_hours - start_hours;
  local s_half = start_minutes ~= shift_minutes;
  if s_half then shift = shift - 1; end

  if start_minutes == '30' and has_decimal ~= nil then
    start_hours = start_hours + 1;
  end
  if (end_hours - start_hours % 24) ~= interval
    or ((start_minutes == end_minutes) and has_decimal ~= nil)
    or ((start_minutes ~= end_minutes) and has_decimal == nil)
  then
    error_msg = string.format(' -- interval error %s %s %s %s-%s ~= %s', start_minutes, end_minutes, has_decimal, end_hours, start_hours, interval)
  end

  if debug_mode then
    vim.notify(
      string.format('[wikiscripts] parsed day line: \nint: %s (has_decimal: %s); start: %s; end: %s; slot: %s', interval, has_decimal, starting_time, ending_time, slot),
      vim.log.levels.INFO
    )
  end

  if debug_mode then
    vim.notify(
      string.format('[wikiscripts] new starting time: %s; shifting %s hours %s minutes...', prev_end, shift, s_half)
    )
  end

  starting_time = updateTime(starting_time, shift, s_half);
  ending_time = updateTime(ending_time, shift, s_half);

  if debug_mode then
    vim.notify(
      string.format('[wikiscripts] updated day line: \nint: %s (has_decimal: %s); start: %s; end: %s; slot: %s', interval, has_decimal, starting_time, ending_time, slot),
      vim.log.levels.INFO
    )
  end

  local minutes_suffix = has_decimal and '.5h' or 'h  '
  local spaces = (' '):rep(15 - slot:len())

  return string.format('%s%s - %s%s( %s - %s )%s', interval, minutes_suffix, slot, spaces, starting_time, ending_time, error_msg), ending_time;
end

local function getInitialUpdateTime()
  local line = vim.api.nvim_get_current_line();
  local _, _, _, _, _, ending_time = line:find(day_line_pattern)

  return ending_time;
end

local function WikiScriptsRecalculateDay()
  -- get linenr under cursor
  local init_line = vim.api.nvim_win_get_cursor(0)[1];
  local prev_time = getInitialUpdateTime();
  if debug_mode then
    vim.notify(
      string.format('[wikiscripts] init_line: %s; init_time: %s\n', init_line, prev_time),
      vim.log.levels.INFO
    );
  end

  local curr_line = init_line + 1;
  local new_line = '';
  local all_lines = vim.fn.getline(init_line + 1, '$');
  for _, line in ipairs(all_lines) do
    if line:match(terminator) then
      return
    end

    if not line:match(day_line_pattern) then
      goto continue;
    end

    new_line, prev_time = updateDayLine(line, prev_time);

    vim.api.nvim_buf_set_lines(0, curr_line - 1, curr_line, false, { new_line })

    ::continue::
    curr_line = curr_line + 1;
  end

  -- get time/interval under cursor
  -- update current line
  -- simple: get final time from current line
  -- update all future lines
  -- local res = updateDayLine("3.5h - fast           ( 12:30 - 16:00 )", "15:00");
  -- vim.notify(
  --   string.format('[wikiscripts] updated line:\n%s', res),
  --   vim.log.levels.INFO
  -- );
end

local function extract_records()
  -- for current buffer
  -- get:
  -- **(day)**
  --   **(time)**
  --   **(slot)** (spent time) (task)
  --
  -- format that as:
  -- day: slot: time - spent time - task
  --            time - spent time - task
  --            total time

  -- get current buffer
  local day_pattern = [[^%*%*(.-)%*%*$]];
  local time_pattern = [[%*%*([%d]+:[%d]+)%*%*$]];
  -- local slot_pattern = [[%*%*(.+)%*%*%s([%d]+:[%d]+:[%d]+)%s?(.+)?]];
  local slot_pattern = [[%*%*(.+)%*%*%s([%d]+:[%d]+:[%d]+)%s-(.-)$]];

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local result = {}
  local time = "";
  local day = "";
  for _, line in ipairs(lines) do
    if line:match(day_pattern) then
      local _, _, currday = line:find(day_pattern);

      result[currday] = {}
      day = currday
      goto continue_cycle
    end

    if line:match(time_pattern) then
      local _, _, currtime = line:find(time_pattern);
      time = currtime;
      goto continue_cycle
    end

    if line:match(slot_pattern) then
      local _, _, slot_name, spent_time, task_name = line:find(slot_pattern)

      if result[day][slot_name] == nil then
        result[day][slot_name] = {}
      end

      result[day][slot_name][#result[day][slot_name] + 1] = {
        time = time,
        spent_time = spent_time,
        task = task_name
      }

      -- table.insert(result, string.format("  %s  %s - %s    %s", time, slot_name, spent_time, task_name))
    end

    ::continue_cycle::
  end

  local end_line = #lines;
  vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {("calculated cycle:"):format(#result)})
  end_line = end_line + 1

  -- vim.api.nvim_put({tprint(result)}, 'l', true, true)

  -- group forematted by day+slot
  -- group formatted by task

  local function sortedPairs(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0;
    local iter = function ()
      i = i + 1;
      if a[i] == nil then return nil
      else return a[i], t[a[i]]
      end
    end
    return iter;
  end

  local dayPartsPattern = [[(w%d+)%s*(%a*)%s*(%d+.%d+.%d+)]];
  local datePattern = [[(%d+).(%d+).(%d+)]];
  local spent_time_pattern = [[(%d+):(%d+):(%d+)]]
  local sortingDaysFn = function (a, b)
    local week1, dow1, date1 = a:match(dayPartsPattern);
    local week2, dow2, date2 = b:match(dayPartsPattern);

    local d1, m1, y1 = date1:match(datePattern);
    local d2, m2, y2 = date2:match(datePattern);

    if (y1 ~= y2) then return tonumber(y1) < tonumber(y2) end
    if (m1 ~= m2) then return tonumber(m1) < tonumber(m2) end
    return tonumber(d1) < tonumber(d2)
  end

  local slotsPriority = {
    physic = 0;
    tidying = 1;
    maint = 2;
    fast = 3;
    slow = 4;
    think = 5;
  };

  local sortingSlotsFn = function (a, b)
    local ap = slotsPriority[a];
    local bp = slotsPriority[b];

    if ap == nil then
      ap = 6;
    end

    if bp == nil then
      bp = 6;
    end

    return ap < bp;
  end

  local slots_report = {};

  -- day-based report
  for cday, slots in sortedPairs(result, sortingDaysFn) do
    if slots == nil then
      goto next_line;
    else
      vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {cday});
      end_line = end_line + 1;
    end

    for slot, slot_records in pairs(slots) do
      vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {slot});
      end_line = end_line + 1;

      for _, details in pairs(slot_records) do
        local line = string.format("    %s: %s - %s", details.time, details.spent_time, details.task);
        vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {line});
        end_line = end_line + 1;

        if slots_report[slot] == nil then
          slots_report[slot] = {}
        end
        if slots_report[slot][cday] == nil then
          slots_report[slot][cday] = {}
        end

        table.insert(slots_report[slot][cday], details);
      end
    end

    vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {""});
    end_line = end_line + 1;

    ::next_line::
  end

  --slot-based report
  vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {""});
  end_line = end_line + 1;
  vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {"slots:"});
  end_line = end_line + 1;

  local tasks_report = {}
  local fill_report = {};

  local slot_prefix = "";
  local day_prefix = "";
  local is_first_slot = true;
  local is_first_day = true;
  for slot, days in pairs(slots_report) do
    if (tasks_report[slot] == nil) then
      tasks_report[slot] = {}
    end

    vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {""});
    end_line = end_line + 1;
    vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {"**"..slot..'**:'});
    end_line = end_line + 1;
    -- prefix = (" "):rep(slot:len()+2);
    -- slot_prefix = slot..": ";
    -- is_first_slot = true;

    for cday, records in sortedPairs(days, sortingDaysFn) do
      local week, dow, date = cday:match(dayPartsPattern);

      day_prefix = slot_prefix..cday..": "
      is_first_day = true;

      if (is_first_slot) then
        is_first_slot = false;
        slot_prefix = (" "):rep(slot_prefix:len());
      end

      if fill_report[week] == nil then
        fill_report[week] = {}
      end

      if fill_report[week][slot] == nil then
        fill_report[week][slot] = {}
      end

      if fill_report[week][slot][cday] == nil then
        fill_report[week][slot][cday] = 0
      end

      for _, record in ipairs(records) do

        if tasks_report[slot][record.task] == nil then
          tasks_report[slot][record.task] = {
            spent_5 = 0;
            spent_10 = 0;
            spent_full = 0;
          };
        end

        local h, m, _ = record.spent_time:match(spent_time_pattern);
        h = tonumber(h)
        m = tonumber(m)

        if (m > 40) then
          h = h + 1;
          m = 0;
        end

        tasks_report[slot][record.task].spent_5 = tasks_report[slot][record.task].spent_5 + h;
        fill_report[week][slot][cday] = fill_report[week][slot][cday] + h;

        local spent_hours = h;
        if (m > 10 or h == 0 and m <= 10) then
          m = 30;
          tasks_report[slot][record.task].spent_5 = tasks_report[slot][record.task].spent_5 + 0.5;
          spent_hours = spent_hours + 0.5;
          fill_report[week][slot][cday] = fill_report[week][slot][cday] + 0.5;
        end

        local converted_m = 0;
             if (m <= 10) then converted_m = 0.17
        else if (m <= 20) then converted_m = 0.34
        else if (m <= 30) then converted_m = 0.5
        else if (m <= 40) then converted_m = 0.67
        else if (m <= 50) then converted_m = 0.84
        end end end end end

        tasks_report[slot][record.task].spent_10 = tasks_report[slot][record.task].spent_10 + h + converted_m

        vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {(day_prefix.."%s: %3sh %8s - %s"):format(record.time, spent_hours, record.spent_time, record.task)});
        end_line = end_line + 1;

        if (is_first_day) then
          is_first_day = false;
          day_prefix = (" "):rep(day_prefix:len());
        end
      end
    end
  end

  for slot, tasks in pairs(tasks_report) do
    vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {""});
    end_line = end_line + 1;
    vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {slot..":"});
    end_line = end_line + 1;

    for task, times in pairs(tasks) do
      -- times.spent_10 disabled since it's calculating weirdly
      vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {("  %5sh - %s"):format(times.spent_5, task)});
      end_line = end_line + 1;
    end
  end

  vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {""});
  end_line = end_line + 1;
  for week, slots in pairs(fill_report) do
    local line = "| "..week.." | "
    -- for slot, _ in pairs(slotsPriority) do
    -- this should map all days and all slots to handle empty days as well
    for slot, days in sortedPairs(slots, sortingSlotsFn) do
      for day, fill in sortedPairs(days, sortingDaysFn) do
        if slot == 'cooking' or slot == 'overflow' then goto continue end
        if slot == 'physic' then
          if fill == 0.5 then line = line..'o';
          elseif fill >= 1 then line = line..'X';
          else line = line..'-';
          end
        elseif slot == 'tidying' or slot == 'maint' then
          if fill >= 0.5 then line = line..'X';
          else line = line..'-';
          end
        elseif slot == 'fast' then
          if fill > 0 and fill <= 1 then line = line..'.';
          elseif fill <= 2 then line = line..'o';
          elseif fill <= 3 then line = line..'O';
          elseif fill > 3 then line = line..'X';
          else line = line..'-';
          end
        elseif slot == 'slow' or slot == 'think' then
          if fill > 0 and fill <= 0.5 then line = line..'.';
          elseif fill <= 1 then line = line..'o';
          elseif fill <= 1.5 then line = line..'O';
          elseif fill > 1.5 then line = line..'X';
          else line = line..'-';
          end
        end
      end
      line = line.." | "
      ::continue::
    end
    vim.api.nvim_buf_set_lines(0, end_line, end_line, false, {line});
    end_line = end_line + 1;
  end
end

local function WikiScriptsRecalculateCycle()
  extract_records();
end

vim.api.nvim_create_user_command("WikiScriptsFillBuffers", WikiScriptsFillBuffers, {});
vim.api.nvim_create_user_command("WikiScriptsRecalculateDay", WikiScriptsRecalculateDay, {});
vim.api.nvim_create_user_command("WikiScriptsRecalculateCycle", WikiScriptsRecalculateCycle, {});


