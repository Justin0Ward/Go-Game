
--# Main

-- Go

-- TODO: 
--[[
- add game rules, like surrounding captures, keep track of captures, no joseki
- add a automatic counting algorithm? or a japanese rules counting helper?
- add an undo button

- pop up window when clearing the board, ask yes or no

- make the single piece drawing into a better state machine
    
- refactor drawing the board into methods of board "class"

- change how touch is handled, remove global refefence to board

- add and refactor so a differnt sized board can be swapped too

- meep track of last placed stone

- swap true to false for Player or white and black meanings of 1 or 2
]]--

require(asset.documents.Libraries.Tools)

Colors = {
    blank = color(0,0),
    board = color(209, 154, 65),
    blk = color(50),
    blkHi = color(70),
    blkBrdr = color(0),
    wht = color(225),
    whtHi = color(235),
    whtBrdr = color(140)
}

function setup()
    viewer.mode = FULLSCREEN
    F = 0
    
    -- new board:
    History = {}
    BoardSizes = {
        Small = 9,
        Medium = 13,
        Large = 19
    }
    BoardSelection = "Large"
    Board = NewBoard(BoardSizes[BoardSelection])
    BoardScale = 0
    BoardLocation = vec2(0,0)
    Player = false
    
    Captures = {
        w = 0,
        b = 0
    }
    
    Liberties = {}
    LibertCount = 0
    Marks = {}
    
    parameter.boolean("scatter", false)

    setupButtons()

end

function setupButtons()
    ColorsUI = {
        Darker = color(180, 120, 40),
        Lighter = color(220, 170, 80)
    }
    
    clearBtnRect = Rectangle(
        WIDTH/2 - 100, 0 + HEIGHT/6,
        200, 50
    )
    clearBtn = NewButton(
        clearBtnRect, "Clear"
    )
    clearBtn.offFill = ColorsUI.Darker
    clearBtn.onFill = ColorsUI.Lighter

    undoBtnRect = Rectangle(
        WIDTH*3/4, HEIGHT/6,
        50, 50
    )
    undoBtn = NewButton(
        undoBtnRect, "<-"
    )
    undoBtn.offFill = ColorsUI.Darker
    undoBtn.onFill = ColorsUI.Lighter
    
end

-- -----------------------------

function update()
    F = F + 1
    
    if F % 30 == 0 and scatter then
        -- randomly place stones
        Board.grid[math.floor(math.random(1,BoardSizes[BoardSelection]))][math.floor(math.random(1,BoardSizes[BoardSelection]))] = math.floor(math.random(-1,1))
        
    end
    
    function clearBtn.act()
        clearBoard(Board.grid)
        print("board cleared on " .. os.date())
    end
    function undoBtn.act()
        undoMove(Board.grid)
        print("un-did")
    end
    
end

-- -----------------------------

function draw()
    update()
    background(Colors.board)
    
    DrawBoard(Board.grid, BoardLocation)
    
    --drawMarked(Board.grid, BoardLocation)
    
    clearBtn:updateDraw()
    undoBtn:updateDraw()
    
    drawLastPlayed(Board.grid, BoardLocation)
    
    local str = "B:"..Captures.b.." W:"..Captures.w
    text(str, WIDTH/2, HEIGHT* 1/9)
    
    drawHistory()
    
end

-- ----------------------

function touched(touch)
    if touch.state == BEGAN then
        placeStone(Board, touch)
    end
end
--# BoardStuff
-- fill a 2D array for pieces, -1, 0, or 1
function NewBoard(_size)
    local size = _size or 19
    local squareSize = WIDTH/size
    local pos = vec2(
    WIDTH/2 - (squareSize * size)/2,
    HEIGHT/2 - (squareSize * size)/2
    )
    
    local tempBoard = {}
    for i = 1, size do
        tempBoard[i] = {}
        for j = 1, size do
            tempBoard[i][j] = -1
        end
    end
    
    local board = {}
    
    board.grid = tempBoard
    board.row = size
    board.col = size
    board.size = squareSize
    board.pos = pos
    
    return board
end

function clearBoard(_board)
    local x, y = #_board, #_board[1]
    
    for i = 1, x do
        for j = 1, y do
            _board[i][j] = -1
        end
    end

    sound(SOUND_EXPLODE, 274)

    History = {}
    
    Liberties = {}
    LibertCount = 0
    Marks = {}
    Captures.w = 0
    Captures.b = 0
end


-- --------------------------
    
function drawHistory()
    local count = #History
    local firstIndex = math.max(1, count - 2)
    
    local Hline = 0
    for i = firstIndex, count do
        text(History[i], WIDTH/2, HEIGHT - 100 - (Hline * 20))
        Hline = Hline + 1
    end
end

function drawLastPlayed(_board, _offset)
    local x = #_board
    local y = #_board[1]
    local size = WIDTH/x + BoardScale
    local offset = _offset or vec2(0,0)
    local boardPos = vec2(
    (WIDTH/2 - (size * x)/2) + size/2+ offset.x,
    (HEIGHT/2 - (size * y)/2) + size/2+ offset.y
    )
    
    
    --[[
    -- get coords from history:
    local hx, hy
    local str = History[#History]
    
    if not str then
        return
    end
        
    local col = str:sub(1,1)
    str = str:sub(3)
    hx, hy = str:match("([^,]+),([^,]+)")
    hx = tonumber(hx) - 1
    hy = tonumber(hy) - 1
    ]]

    local col, hx, hy = parseHistory()
    if not (col or hx or hy) then return end
    
    pushStyle()
    
    strokeWidth(1 * size/10)
    noFill()
    
    if col == "B" then
        stroke(Colors.wht)
    elseif col == "W" then
        stroke(Colors.blk)
    else
        stroke(128)
    end
        
    ellipse(
        (hx-1) * size + boardPos.x,
        (hy-1) * size + boardPos.y,
        size*7/10
    )
    
    popStyle()
end

function parseHistory()
    -- get coords from history:
    local hx, hy
    local str = History[#History]
    
    if not str then
        return nil
    end
    
    local col = str:sub(1,1)
    str = str:sub(3)
    hx, hy = str:match("([^,]+),([^,]+)")
    hx = tonumber(hx)
    hy = tonumber(hy)
    
    return col, hx, hy
end

function undoMove(_board)
    -- TODO: need to record what coatures just happened...
    
    local _, hx, hy = parseHistory()
    if not (hx or hy) then return end
    
    _board[hx][hy] = -1
    
    sound(SOUND_BLIT, 44481)
    
    Liberties = {}
    LibertCount = 0
    Marks = {}
    table.remove(History)
    
    Player = not Player
    
end

-- draw all pieces on board acording to 2D array
function DrawPieces(_board, _offset)
    local x = #_board
    local y = #_board[1]
    local size = WIDTH/x + BoardScale
    local offset = _offset or vec2(0,0)
    local boardPos = vec2(
    (WIDTH/2 - (size * x)/2) + size/2+ offset.x,
    (HEIGHT/2 - (size * y)/2) + size/2+ offset.y
    )
    
    pushStyle()
    
    for i = 1, x do
        for j = 1, y do
            local piece = _board[i][j]
            
            if piece >= 0 then
                DrawSinglePiece(piece, i, j, boardPos, size)
            end
        end
    end
    
    popStyle()
end

-- draw a piece, so that style can be changed
function DrawSinglePiece(_piece, _x, _y, _bP, _size)
    
    local p = _piece
    local px = _size * (_x - 1) + _bP.x
    local py = _size * (_y - 1) + _bP.y
    local s = _size
    local hiOffX = s/10 * -0.2
    local hiOffY = s/10 * 2
    local hiWidth = s/2
    local hiHeight = s/2.5
    
    -- piece proper:
    
    if p == 1 then
        stroke(Colors.whtBrdr)
        fill(Colors.wht)
    elseif p == 0 then
        stroke(Colors.blkBrdr)
        fill(Colors.blk)
    end
    
    strokeWidth(1)
    
    -- shadow:
    pushStyle()
    
    noStroke()
    fill(0,0,0,25)
    
    local mod = 1
    local count = 4
    for i=0, count do
        local off = (i * mod)
        ellipse(px+off, py-off, s)
    end
    
    popStyle()
    
    -- piece:
    ellipse(px, py, s)
    
    -- highlight:
    if p == 1 then
        fill(Colors.whtHi)
    elseif p == 0 then
        fill(Colors.blkHi)
    end
    
    noStroke()
    
    pushMatrix()
    
    translate(px, py)
    rotate(45)
    
    ellipse(hiOffX, hiOffY, hiWidth, hiHeight)
    
    popMatrix()
end

-- Draw the lines of the board
function DrawBoard(_board, _offset)
    local x, y = #_board, #_board[1]
    local size = WIDTH/x + BoardScale
    local offset = _offset or vec2(0,0)
    local boardPos = vec2(
    (WIDTH/2 - (size * x)/2) + size/2 + offset.x,
    (HEIGHT/2 - (size * y)/2) + size/2 + offset.y
    )
    
    pushStyle()
    
    strokeWidth(1.5)
    stroke(0)
    
    local py = (size * y) - size
    for i = 0, x - 1 do
        local lx = size * i
        line(
        lx + boardPos.x,
        py + boardPos.y,
        lx + boardPos.x,
        boardPos.y
        )
    end
    
    local px = (size * x) - size
    for i = 0, y - 1 do
        local ly = size * i
        line(
        boardPos.x,
        ly + boardPos.y,
        px + boardPos.x,
        ly + boardPos.y
        )
    end
    
    DrawBoardDots(_board, boardPos)
    
    popStyle()
    
    DrawPieces(_board, _offset)
    
end

-- draws the dots at the corners, edges, and center
function DrawBoardDots(_board, _pos)
    local x, y = #_board, #_board[1]
    local size = WIDTH / x + BoardScale
    local centerX = math.floor(x / 2 + 0.5)
    local centerY = math.floor(y / 2 + 0.5)
    local dotSize = strokeWidth() * 5
    local dotOffset = 0
    
    fill(0)
    noStroke()
    
    -- hard coded sizes based on go board standard sizes
    if x == 19 then
        dotOffset = 7
    elseif x == 13 then
        dotOffset = 4
    elseif x == 9 then
        dotOffset = 2
    end
    
    for i = 1, x do
        local k = i - centerX
        local px = size * (i - 1) + _pos.x
        
        for j = 1, y do
            local l = j - centerY
            local py = size * (j - 1) + _pos.y
            
            local isCorner =
            (math.abs(k) == dotOffset
            and
            math.abs(l) == dotOffset)
            
            local isEdge = false
            if x == 19 then
                isEdge =
                (math.abs(l) == 0 and math.abs(k) == dotOffset)
                or
                (math.abs(k) == 0 and math.abs(l) == dotOffset)
            end
            
            local isCenter =
            k == 0 and l == 0
            
            if isCorner or isEdge or isCenter then
                ellipse(px, py, dotSize)
            end
        end
    end
end

-- ------------

-- TODO: somehow broken when displaying alternating turns, sometikes gets stuck only displaying last plays marks and libs, probably to do with how the tables are set.
function drawMarked(_board, _offset)
    local x = #_board
    local y = #_board[1]
    local size = WIDTH/x + BoardScale
    local offset = _offset or vec2(0,0)
    local boardPos = vec2(
    (WIDTH/2 - (size * x)/2) + size/2+ offset.x,
    (HEIGHT/2 - (size * y)/2) + size/2+ offset.y
    )
    
    
    for m in pairs(Marks) do
        local x, y = m:match("([^,]+),([^,]+)")
        x = tonumber(x)
        y = tonumber(y)
        x = x - 1
        y = y - 1
        fill(232, 30, 45)
        ellipse(x * size + boardPos.x,
        y * size + boardPos.y, size/2)
    end
    
    for m in pairs(Liberties) do
        local x, y = m:match("([^,]+),([^,]+)")
        x = tonumber(x)
        y = tonumber(y)
        x = x - 1
        y = y - 1
        fill(122, 232, 30)
        ellipse(x * size + boardPos.x,
        y * size + boardPos.y, size/2)
    end
    
end
--# Calculating

function placeStone(_board, _touch)
    local gridCols = _board.col
    local gridRows = _board.row
    local cellSize = _board.size
    
    local cellX = math.floor((_touch.x - _board.pos.x) / cellSize) + 1
    local cellY = math.floor((_touch.y - _board.pos.y) / cellSize) + 1
    
    if not (
    cellX >= 1 and cellX <= gridCols and
    cellY >= 1 and cellY <= gridRows) then
        return
    end
    
    if _board.grid[cellX][cellY] < 0 then
        _board.grid[cellX][cellY] = Player and 1 or 0
        
        -- TODO: account for suicide
        -- TODO: doesnt show marks and liberties when black plays?...
        
        sound(SOUND_PICKUP, 28883)
        
        LibertCount = 0
        Marks = {}
        Liberties = {}
        
        for x=1, #_board.grid do
            for y=1, #_board.grid[1] do
                -- could probbaly check just the opposide player color
                if _board.grid[x][y] >= 0 then
                    LibertCount = 0
                    Marks = {}
                    Liberties = {}
                    
                    local col = Player and 0 or 1
                    count(_board.grid, x, y, col)
                    
                    if LibertCount < 1 then removeMarkedStones(_board, col)
                    end
                end
            end
        end
        
        -- TODO: Change player turn into a state of the board?
        Player = not Player
        local pColor = Player and "B" or "W"
        table.insert(History, pColor..":"..cellX..","..cellY)
    end
end

function removeMarkedStones(_board, col)
    for m in pairs(Marks) do
        local x, y = m:match("([^,]+),([^,]+)")
        x = tonumber(x)
        y = tonumber(y)
        print(x, y)
        if col == 0 then
            Captures.b = Captures.b + 1
        elseif col == 1 then
            Captures.w = Captures.w + 1
        end
        _board.grid[x][y] = -1
    end
end

function count(_board, x, y, givenColor)
    if (x < 1 or x > #_board or y < 1 or y > #_board[1]) then
        return
    end
    
    local currentColor = _board[x][y]
    local loc = x..","..y
    local m = Marks[loc] and true or false

    if currentColor >= 0 and currentColor == givenColor and not m then
        Marks[loc] = true -- marked
        count(_board, x, y + 1, givenColor)
        count(_board, x + 1, y, givenColor)
        count(_board, x, y - 1, givenColor)
        count(_board, x - 1, y, givenColor)
    elseif currentColor == -1 then
        Liberties[loc] = true -- liberty
        LibertCount = LibertCount + 1
    end
end








--[=[ experiments:

function checkCapture(_board, x, y, _player)
    
    -- check all around if any are enemy stones.
    
    -- if enemy stone, check if it is has no liberties,
    -- if no, then check if it has friends,
    -- if yes, check that friend if it has liberies,
    -- if no then check if it has friends,
    -- if no then kill all checked.
    
    local stone = _player and 0 or 1
    
    local W = getNeighbor(_board, x - 1, y)
    local N = getNeighbor(_board, x, y + 1)
    local E = getNeighbor(_board, x + 1, y)
    local S = getNeighbor(_board, x, y - 1)
    
    dirs = {w = W, n = N, e = E, s = S}
        
end

function getNeighbor(_b, x, y)
    if x < 1 or x > #_b+1 or y < 1 or y > #_b[1]+1 then
        return
    end
    return _b[x][y]
end

function checkEnemy(_board, x, y)
    
    if W == -1 or N == -1 or E == -1 or S  == -1 then
        return
    end
end

function checkNeighbors(_board, x, y, _player)
    local plr = _player and 0 or 1
    if _board[x - 1][y] ~= plr then
        killFill(_board, x, y, _board[x-1][y])
    end
end

function killFill(_board, x, y, oldCell)
    if x < 1 or x >= #_board+1 or y < 1 or y >= #_board[1]+1 or _board[x][y] ~= oldCell then
        return
    end
    
    _board[x][y] = -1 -- set to blank
    if oldCell == 1 then
        Captured.white = Captured.white + 1
    elseif oldCell == 0 then
        Captured.black = Captured.black + 1
    end
    
    killFill(_board, x + 1, y, oldCell)    
    killFill(_board, x - 1, y, oldCell)    
    killFill(_board, x, y + 1, oldCell)    
    killFill(_board, x, y - 1, oldCell)
end

function checkConnections(_board, _pos)
    -- look up how to make a fill like algorithm 
    --[[ alogrithm:
    - make list of checked positions.
    - record what color is being checked.
    - add first position to list.
    
    - check N E S W directions of position, if not edge and not in list.
    
    - if a dir is the same color and not empty: add to list.
    - check that new position, do same thing unless checked dir is in list.
    - if no more same clor pieces, go back to start of list and start again, only going to sqaure not in list.
    ]]
    -- scoped variables so my recursive function can see them... i hope
    local dir = {
        vec2(-1,0), -- left
        vec2(0,1), -- up
        vec2(1,0), -- right
        vec2(0,-1) -- down
    }
    local positionSet = {}
    local checkColor = Player and 0 or 1
    -- 1 is white, 0 black
    
    function dive(_cur)
        local cur = _cur.x..",".._cur.y
        positionSet[cur] = true
        --print(positionSet[cur])
        
        for _, d in pairs(dir) do
            local nX, nY = _cur.x + d.x, _cur.y + d.y
            
            if not (nX < 0 and nX > #_board) and (nY < 0 and nY >#_board[1]) then
                local p = _board[nX][nY]
                local c = nX..","..nY
                
                if p == checkColor and not positionSet[c] then
                    positionSet[c] = true
                    -- go again
                end
            end
        end
    end
    
    dive(_pos)
    
    output.clear()
    for k, _ in pairs(positionSet) do
        print(k)
    end
    
end

function checkSurround(_board, _pos)
    local blkCount, whtCount = 0, 0
    
    -- TODO: change to only check straight line no diagnals 
    for i=-1, 1 do
        for j=-1, 1 do
            local x, y = _pos.x + i, _pos.y + j
            
            if i == 0 and j == 0 then
                -- pass
            elseif not (x < 1 or x > #_board or y < 1 or y > #_board[1]) then
                
                local piece = _board[x][y]
                
                if piece == 1 then
                    whtCount = whtCount + 1
                end
                if piece == 0 then
                    blkCount = blkCount + 1
                end
                
            end
            
        end
    end
    
    print("W:"..whtCount.." B:"..blkCount)
end
]=]
