--[[
Ring Meters by londonali1010 (2009)

This script draws percentage meters as rings. It is fully customisable; all options are described in the script.

IMPORTANT: if you are using the 'cpu' function, it will cause a segmentation fault if it tries to draw a ring straight away. The if statement near the end of the script uses a delay to make sure that this doesn't happen. It calculates the length of the delay by the number of updates since Conky started. Generally, a value of 5s is long enough, so if you update Conky every 1s, use update_num > 5 in that if statement (the default). If you only update Conky every 2s, you should change it to update_num > 3; conversely if you update Conky every 0.5s, you should use update_num > 10. ALSO, if you change your Conky, is it best to use "killall conky; conky" to update it, otherwise the update_num will not be reset and you will get an error.

To call this script in Conky, use the following (assuming that you save this script to ~/scripts/rings.lua):
	lua_load ~/scripts/rings-v1.2.1.lua
	lua_draw_hook_pre ring_stats
	
Changelog:
+ v1.2.1 -- Fixed minor bug that caused script to crash if conky_parse() returns a nil value (20.10.2009)
+ v1.2 -- Added option for the ending angle of the rings (07.10.2009)
+ v1.1 -- Added options for the starting angle of the rings, and added the "max" variable, to allow for variables that output a numerical value rather than a percentage (29.09.2009)
+ v1.0 -- Original release (28.09.2009)
]]

--[[
Ring Meters by londonali1010 (2009)
Modified to support:
- Relative positioning (x_rel, y_rel)
- Dynamic radius/thickness scaling
- Temperature-based color for 'custom' ring
- Safe fallbacks for missing values
]]

function read_file(path)
    local file = io.open(path, "r")
    if not file then return 0 end
    local content = file:read("*l")
    file:close()
    if not content then return 0 end
    local num = tonumber(content)
    return num or 0
end

settings_table = {
    {
        name='cpu', arg='cpu0', max=100,
        bg_colour=0xF7768E, bg_alpha=0.2,
        fg_colour=0xF7768E, fg_alpha=1,
        x_rel=0.15, y_rel=0.40,
        radius_scale=5.0, thickness_scale=1.4,
        start_angle=0, end_angle=360,
    },
    {
        name='memperc', arg='', max=100,
        bg_colour=0xBA89A6, bg_alpha=0.2,
        fg_colour=0xBA89A6, fg_alpha=1,
        x_rel=0.35, y_rel=0.88,
        radius_scale=5.0, thickness_scale=1.4,
        start_angle=0, end_angle=360
    },
    {
        name='battery_percent', arg='BAT0', max=100,
        bg_colour=0x8D95AF, bg_alpha=0.2,
        fg_colour=0x8D95AF, fg_alpha=1,
        x_rel=0.55, y_rel=0.88,   -- ✅ 改为相对定位
        radius_scale=5.0, thickness_scale=1.4,
        start_angle=0, end_angle=360
    },
    {
        name='custom', arg='/tmp/conky_cpu_avg_temp', max=100,
        bg_colour=0x7AA2F7, bg_alpha=0.2,
        fg_colour=0x7AA2F7, fg_alpha=1,
        x_rel=0.75, y_rel=0.88,   -- ✅ 改为相对定位
        radius_scale=5.0, thickness_scale=1.4,
        start_angle=0, end_angle=360,
    },
}

require 'cairo'

function rgb_to_r_g_b(colour, alpha)
    return ((colour / 0x10000) % 0x100) / 255.,
           ((colour / 0x100) % 0x100) / 255.,
           (colour % 0x100) / 255.,
           alpha
end

function draw_ring(cr, t, pt)
    local xc, yc = pt.x, pt.y
    local ring_r = pt.radius or 20
    local ring_w = pt.thickness or 5
    local sa, ea = pt.start_angle or 0, pt.end_angle or 360
    local bgc, bga = pt.bg_colour or 0xFFFFFF, pt.bg_alpha or 0.2
    local fgc, fga = pt.fg_colour or 0x00FF00, pt.fg_alpha or 1

    local angle_0 = sa * (2 * math.pi / 360) - math.pi / 2
    local angle_f = ea * (2 * math.pi / 360) - math.pi / 2
    local t_arc = t * (angle_f - angle_0)

    cairo_arc(cr, xc, yc, ring_r, angle_0, angle_f)
    cairo_set_source_rgba(cr, rgb_to_r_g_b(bgc, bga))
    cairo_set_line_width(cr, ring_w)
    cairo_stroke(cr)

    cairo_arc(cr, xc, yc, ring_r, angle_0, angle_0 + t_arc)
    cairo_set_source_rgba(cr, rgb_to_r_g_b(fgc, fga))
    cairo_stroke(cr)
end

function conky_ring_stats()
    if conky_window == nil then return end
    local w, h = conky_window.width, conky_window.height
    if w <= 0 or h <= 0 then return end  -- 防止窗口未初始化

    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, w, h)
    local cr = cairo_create(cs)

    local updates = conky_parse('${updates}')
    local update_num = tonumber(updates) or 0

    -- ✅ 更强的启动保护
    if update_num > 5 and w > 100 and h > 100 then
        for _, pt in ipairs(settings_table) do
            setup_rings(cr, pt)
        end
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

local function setup_rings(cr, pt)
    -- Get value
    local value = 0
    if pt.name == 'custom' then
        value = read_file(pt.arg)
    else
        local str = conky_parse(string.format('${%s %s}', pt.name, pt.arg or ''))
        value = tonumber(str) or 0
    end

    local pct = math.min(1, math.max(0, value / (pt.max or 100)))

    -- Window size
    local win_w, win_h = conky_window.width, conky_window.height
    local base = math.min(win_w, win_h)

    -- Position (must have x_rel/y_rel!)
    local xc = (pt.x_rel and win_w * pt.x_rel) or (win_w * 0.5)
    local yc = (pt.y_rel and win_h * pt.y_rel) or (win_h * 0.5)

    -- Size scaling
    local radius = (pt.radius_scale and base * pt.radius_scale / 100) or 20
    local thickness = (pt.thickness_scale and base * pt.thickness_scale / 100) or 5

    -- Color logic for temperature
    local fg_colour = pt.fg_colour
    if pt.name == 'custom' then
        local thresholds = {
            {0.75, 0x7AA2F7}, {0.90, 0xE0AF68}, {1.00, 0xF7768E}
        }
        for _, th in ipairs(thresholds) do
            if pct <= th[1] then
                fg_colour = th[2]
                break
            end
        end
    end

    draw_ring(cr, pct, {
        x = xc, y = yc,
        radius = radius,
        thickness = thickness,
        start_angle = pt.start_angle,
        end_angle = pt.end_angle,
        bg_colour = pt.bg_colour,
        bg_alpha = pt.bg_alpha,
        fg_colour = fg_colour,
        fg_alpha = pt.fg_alpha
    })
end