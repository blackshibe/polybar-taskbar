# polybar-taskbar

Small Lua script that works like a taskbar when used with polybar.
I don't know why you would ever want this, but I had the thought, and now it's here.

![hopefully I embedded this correctly](demo.png)

# Configuration

```
[module/taskbar]
type = custom/script
interval = 0.1
label-foreground = ${colors.foreground}
label-background = ${colors.background}
label = %output%
format = <label>
exec = lua ~/.config/polybar/taskbar.lua
```