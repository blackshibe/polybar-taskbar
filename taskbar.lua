---@diagnostic disable: redefined-local

-- pretty simple innit
local focused_text_color = "#93abbb"
local primary_text_color = "#ffffff"
local focused_bg_color = "#171617"
local primary_bg_color = "#262222"
local max_shown_chars = 40

local start = os.clock()

-- https://stackoverflow.com/questions/1426954/split-string-in-lua#7615129
local function split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

local function gib_color(mode, color)
	return "%{" .. mode .. color .. "}"
end

local function truncate(title)
	if #title < max_shown_chars then
		return title
	else
		return title:sub(1, max_shown_chars) .. "..."
	end
end

-- example output line:
-- 0x02800003  0 blackshibe-arch 🦊 taskbar.lua - polybar - Visual Studio Code
local raw_open_apps = io.popen("wmctrl -l", "r"):read("a")
local raw_open_apps_output = split(raw_open_apps, "\n")
local windows = {}

-- code assumes the username has no tabs
for _, v in pairs(raw_open_apps_output) do
	local split_str = split(v, "    ")

	-- get more accurate title
	-- this is slow but the whole thing runs in 2ms lol who cares

	-- _OB_APP_CLASS(UTF8_STRING) = "Firefox"
	local real_shit = io.popen("xprop -id " .. split_str[1], "r"):read("a")
	local app_class = real_shit:find("_OB_APP_CLASS")
	local rest = real_shit:sub(app_class, -1)
	local nl = rest:find("\n")
	local start, finish = rest:sub(1, nl):find('%b""')

	-- polybar has this username(?)
	-- so I am assuming it means the process is not supposed to not show up
	if split_str[3] ~= "N/A" then
		table.insert(windows, {
			addr = split_str[1],
			desktop = split_str[2],
			username = split_str[3],
			title = rest:sub(start + 1, finish - 1),
		})
	end
end

-- example output:
-- 0  * DG: 1920x1080  VP: 0,0  WA: 1,1 1918x1037  desktop 1
-- 1  - DG: 1920x1080  VP: 0,0  WA: 1,1 1918x1037  desktop 2
-- 2  - DG: 1920x1080  VP: 0,0  WA: 1,1 1918x1037  desktop 3
-- 3  - DG: 1920x1080  VP: 0,0  WA: 1,1 1918x1037  desktop 4
local raw_desktops = split(io.popen("wmctrl -d", "r"):read("a"), "\n")
local open_desktop = "0"

-- find open desktop
for _, v in pairs(raw_desktops) do
	local split_str = split(v, "    ")
	if split_str[2] == "*" then
		open_desktop = split_str[1]
		break
	end
end

-- find focused window

-- example output:
-- _NET_ACTIVE_WINDOW(WINDOW): window id # 0x1600007
local raw_focused = split(io.popen("xprop -root _NET_ACTIVE_WINDOW", "r"):read("a"), "  ")
local current_focused_window = raw_focused[5]:sub(3, -2)
local output = ""

for _, v in pairs(windows) do
	if v.desktop == open_desktop then
		-- xprop cuts up zeroes in hex addresses while wmctrl does not,
		-- so find must be used instead of a comparison
		-- this may break shit lol

		-- add button
		output = output .. "%{A1:wmctrl -i -a " .. v.addr .. ":}"

		-- add color
		if v.addr:find(current_focused_window) then
			output = output .. gib_color("F", focused_text_color)
			output = output .. gib_color("B", focused_bg_color)
		else
			output = output .. gib_color("F", primary_text_color)
			output = output .. gib_color("B", primary_bg_color)
		end

		-- add title
		output = output .. string.format(" [%s]", truncate(v.title))
		output = output .. "%{A1} "
	end
end

-- runs in about 2ms
-- io.write(((os.clock() - start) * 1000) .. "ms ")

io.write(output)
