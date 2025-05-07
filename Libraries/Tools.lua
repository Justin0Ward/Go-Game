
--# Main
-- Tools

-- Main file.
-- small example:

function setup()
    viewer.mode = FULLSCREEN
    
    myButton = NewButton(
        Rectangle(
            WIDTH/2 - 150, HEIGHT/4,
            300, 150
        ),
        "Press Me"
    )
end

function draw()
    background(200)
    
    myButton:updateDraw()
    
    function myButton.act() 
        -- do something I'm giving up on you.
    end
end

--# Maths
function hex2Binary(hexCode)
    
    local binaryCode = {}
    
    for i = 1, #hexCode do
        local hexChar = string.sub(hexCode, i, i)
        local decimal = tonumber(hexChar, 16)
        local binary = dec2Binary(decimal)
        
        table.insert(binaryCode, binary)
    end
    
    return table.concat(binaryCode)
    
end

function dec2Binary(num)
    
    local bin = ""
    
    while num > 0 do
        bin = (num % 2) .. bin
        num = math.floor(num / 2)
    end
    
    -- repeat string and concat, to add leading 0s
    return string.rep("0", 4 - (#bin > 0 and #bin or 0)) .. bin
    
end

function formatClock(n)
    local seconds_in_minute = 60
    local seconds_in_hour = 60 * seconds_in_minute
    local seconds_in_day = 24 * seconds_in_hour
    local seconds_in_month = 30 * seconds_in_day -- assuming 30 days/month
    local seconds_in_year = 12 * seconds_in_month -- assuming 12 months/year
    
    local years = math.floor(n / seconds_in_year)
    n = n % seconds_in_year
    
    local months = math.floor(n / seconds_in_month)
    n = n % seconds_in_month
    
    local days = math.floor(n / seconds_in_day)
    n = n % seconds_in_day
    
    local hours = math.floor(n / seconds_in_hour)
    n = n % seconds_in_hour
    
    local minutes = math.floor(n / seconds_in_minute)
    local seconds = n % seconds_in_minute
    
    return
    string.format("%02d", years) .. "y:" ..
    string.format("%02d", months) .. "m:" ..
    string.format("%02d", days) .. "d:" ..
    string.format("%02d", hours) .. "h:" ..
    string.format("%02d", minutes) .. "m:" ..
    string.format("%02d", seconds) .. "s"
end
--# Tools
-- Tools

function Rectangle(x, y, width, height)
    return {x = x, y = y, width = width, height = height}
end

-- takes a point and a rectanlge and returns a boolean
function PointRectCollision(p, r)
    return p.x >= math.min(r.x, r.x + r.width) and p.x <= math.max(r.x, r.x + r.width)
    and p.y >= math.min(r.y, r.y + r.height) and p.y <= math.max(r.y, r.y + r.height)
end

-- i guess this is the linear space algorithm?
function Linspace(x, y, n)
    local frames = {}
    if n <= 1 then
        frames[1] = x
        return frames
    end
    
    local step = (y - x) / (n - 1)
    
    for i = 0, n - 1 do
        frames[i + 1] = x + step * i
    end
    
    return frames
end

-- requires global FPS = 0 and F + 1 being added every frame
function DrawFPS()
    pushStyle()
    
    if F % 3 == 0 then
        FPS = 1 / DeltaTime
    end
    
    fontSize(12)
    rectMode(CENTER)
    
    local fpsStr = string.format("%2.1f", FPS)
    local fpsStrW, fpsStrH = textSize(fpsStr)
    local screenOffset = 25
    
    local midpoint = vec2(
    0 + fpsStrW/2 + screenOffset,
    HEIGHT - fpsStrH/2 - screenOffset
    )
    
    fill(0)
    rect(
    midpoint.x, midpoint.y,
    fpsStrW + fpsStrW/5, fpsStrH
    )
    
    fill(0, 255, 0)
    text(fpsStr,
    midpoint.x,
    midpoint.y
    )
    
    popStyle()
end

-- assign to variable in setup, call :updateDraw() in draw(), overload .act() for action on release.
-- dependant on Rectangle() and PointRectCollision()
function NewButton(btnRec, btnText)
    local btn = {}
    btn.touched = false
    --btn.pressed = false
    btn.rectangle = btnRec
    btn.text = btnText
    
    btn.onFill = color(23, 228, 222)
    btn.offFill = color(215, 224, 222)
    btn.outlineColor = color(25, 25, 25)
    btn.textColor = color(25, 25, 25)
    
    btn.act = function() end
    
    function btn.updateDraw(this)
        popStyle()
        local collide = PointRectCollision(CurrentTouch, this.rectangle)
        
        -- toggled touched once within a loop
        if collide and
        not this.touched and CurrentTouch.state == BEGAN then
            this.touched = true
        elseif this.touched and CurrentTouch.state == ENDED then
            this.act()
            this.touched = false
        end
        
        local off = {
            x = -1,
            y = -1,
            w = 2,
            h = 2
        }
        
        fill(this.outlineColor)
        rect(this.rectangle.x + off.x,
            this.rectangle.y + off.y,
            this.rectangle.width + off.w,
            this.rectangle.height + off.h
        )
        
        if collide and this.touched then
            fill(this.onFill)
        else
            fill(this.offFill)
        end
        
        rect(this.rectangle.x, this.rectangle.y, this.rectangle.width, this.rectangle.height)
        
        fill(this.textColor)
        text(this.text, this.rectangle.x + this.rectangle.width/2, this.rectangle.y + this.rectangle.height/2)
        
        pushStyle()
    end
    
    return btn
end
