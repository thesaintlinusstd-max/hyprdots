-- minimal-subtools.lua
-- mpv script for subtitle navigation and translation
-- Config: script-opts/minimal-subtools.conf or --script-opts=minimal-subtools-key_translate=Alt+t

local function replay()
  local t = mp.get_property_number("sub-start")
  if t then mp.commandv("seek", t, "absolute"); mp.set_property("pause", "yes") end
end

local function loop_toggle()
  local a = mp.get_property("ab-loop-a")
  if a ~= "no" then
    mp.set_property("ab-loop-a", "no"); mp.set_property("ab-loop-b", "no")
    mp.osd_message("🔁 Loop off", 2)
  else
    local sa = mp.get_property_number("sub-start")
    local sb = mp.get_property_number("sub-end")
    if not sa or not sb then mp.osd_message("No sub timing", 2); return end
    mp.set_property_native("ab-loop-a", sa)
    mp.set_property_native("ab-loop-b", sb)
    mp.osd_message("🔁 Loop on", 2)
  end
end

local SUB_FILE = "/tmp/mpv-sub.txt"
local WRAPPER = (os.getenv("HOME") or "/root") .. "/.config/waybar/scripts/mpv-sub-open.fish"

local function translate()
  local text = mp.get_property("sub-text")
  if not text or text == "" then mp.osd_message("No subtitle", 2); return end
  -- Safer cleaning pipeline: validate and strip problematic characters
  text = text:gsub("<[^>]+>", ""):gsub("\n", " ")
  text = text:gsub('^"|"$', ""):gsub("\\", "")
  -- Trim and check if we have meaningful text after cleaning
  text = text:match("^%s*(.-)%s*$")
  if not text or #text < 2 then
    mp.osd_message("Subtitle too short/clean", 2)
    return
  end
  -- Sync handoff via file (no clipboard race), then open EXACT same popup as Alt+W
  local f = io.open(SUB_FILE, "w")
  if f then f:write(text); f:close() end
  mp.commandv("run", "wl-copy", text)
  mp.commandv("run", "fish", WRAPPER)
  mp.osd_message("🦆 Duck.ai: sent", 2)
end

local function loop_points()
  local a = mp.get_property("ab-loop-a")
  local b = mp.get_property("ab-loop-b")
  if a == "no" or b == "no" then return nil, nil end
  return tonumber(a), tonumber(b)
end

-- Wait until the seek settles on the NEW subtitle, then move the loop there.
-- (A fixed 0.25s timer is too short for slow/network seeks and would
-- re-anchor onto the stale OLD timing.)
local function reanchor_loop(old_sa, fallback_a, fallback_b, tries)
  tries = tries or 0
  local sa = mp.get_property_number("sub-start")
  local sb = mp.get_property_number("sub-end")
  if sa and sb and sa ~= old_sa then
    mp.set_property_native("ab-loop-a", sa)
    mp.set_property_native("ab-loop-b", sb)
    mp.osd_message("🔁 Loop → sub", 2)
  elseif tries < 20 then
    mp.add_timeout(0.1, function() reanchor_loop(old_sa, fallback_a, fallback_b, tries + 1) end)
  elseif sa and sb then
    -- Seek didn't move to a new sub (e.g. already at last one): keep looping it.
    mp.set_property_native("ab-loop-a", sa)
    mp.set_property_native("ab-loop-b", sb)
    mp.osd_message("🔁 Loop → sub", 2)
  elseif fallback_a and fallback_b then
    -- No subtitle timing at all: restore the previous loop instead of losing it.
    mp.set_property_native("ab-loop-a", fallback_a)
    mp.set_property_native("ab-loop-b", fallback_b)
    mp.osd_message("🔁 Loop kept", 2)
  end
end

local function sub_step(dir)
  local old_la, old_lb = loop_points()
  local was_loop = old_la ~= nil
  local old_sa = mp.get_property_number("sub-start")
  if was_loop then
    -- Clear first so the core ab-loop doesn't yank playback back to the
    -- old segment while the seek is still in flight.
    mp.set_property("ab-loop-a", "no")
    mp.set_property("ab-loop-b", "no")
  end
  mp.commandv("sub-seek", dir)
  mp.add_timeout(0.06, function() mp.set_property("pause", "yes") end)
  if was_loop then
    mp.add_timeout(0.15, function() reanchor_loop(old_sa, old_la, old_lb, 0) end)
  end
end

local function sub_prev()
  sub_step(-1)
end

local function sub_next()
  sub_step(1)
end

-- Default key bindings (overridable via script-opts)
local opts = {
  key_replay = "r",
  key_loop = "Ctrl+r",
  key_translate = "Ctrl+t",
  key_sub_prev = "shift+left",
  key_sub_next = "shift+right",
  key_sub_prev2 = "ctrl+left",
  key_sub_next2 = "ctrl+right",
}

require("mp.options").read_options(opts, "minimal-subtools")

mp.add_key_binding(opts.key_replay, "replay", replay)
mp.add_key_binding(opts.key_loop, "loop-toggle", loop_toggle)
mp.add_key_binding(opts.key_translate, "translate", translate)
mp.add_key_binding(opts.key_sub_prev, "sub-prev", sub_prev)
mp.add_key_binding(opts.key_sub_next, "sub-next", sub_next)
mp.add_key_binding(opts.key_sub_prev2, "sub-prev2", sub_prev)
mp.add_key_binding(opts.key_sub_next2, "sub-next2", sub_next)

-- ponytail: config via script-opts/minimal-subtools.conf