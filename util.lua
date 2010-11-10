module(..., package.seeall)

-- Takes age in seconds and returns string like "XX days ago"

function age (time)
    local fmt = string.format
    if time > 60*60*24*365*2 then
        return fmt("%d years ago", time/60/60/24/365)
    elseif time > 60*60*24*(365/12)*2 then
        return fmt("%d months ago", time/60/60/24/(365/12))
    elseif time > 60*60*24*7*2 then
        return fmt("%d weeks ago", time/60/60/24/7)
    elseif time > 60*60*24*2 then   
        return fmt("%d days ago", time/60/60/24)
    elseif time > 60*60*2 then
        return fmt("%d hours ago", time/60/60)
    elseif time > 60*2 then
        return fmt("%d min ago", time/60)
    elseif time > 2 then
        return fmt("%d sec ago", time)
    else
        return "right now"
    end
end

