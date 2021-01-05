local player = {}
player.__index = player

function player.new()
    local p = {}
    setmetatable(p, player)

    -- starting position - just centre of first room
    p.x = 256
    p.y = 256
    
    -- current angle for light
    p.angle = 0
    -- table of keys that the player has
    p.keys = {}

    -- texture
    p.texture = love.graphics.newImage("assets/characters.png")
    -- sprite info
    local sprinfo = json.opendecode("assets/characters.json")

    -- setup the sprite info
    p.standing = {right = {}, left = {}, up = {}, down = {}}
    p.walking = {right = {}, left = {}, up = {}, down = {}}

    -- setup the sprites tables by animation/frame number
    for i, v in ipairs(sprinfo.characters) do
        if v.category == "player" then
            local a = nil
            local d = nil
            local d2 = nil

            if v.animation == "standing" then
                a = p.standing
            elseif v.animation == "walking" then
                a = p.walking
            end

            if a then
                if v.direction == "sideways" then
                    d = a.right
                    d2 = a.left
                elseif v.direction == "up" then
                    d = a.up
                elseif v.direction == "down" then
                    d = a.down
                end                
            end

            if d then
                table.insert(
                    d,
                    v.frame,
                    love.graphics.newQuad(v.quad.x, v.quad.y, v.quad.w, v.quad.h, p.texture:getWidth(), p.texture:getHeight())
                )  
                -- print("inserted: " .. v.animation .. " - " .. v.direction .. " - " .. v.frame)
            end
            if d2 then
                table.insert(
                    d2,
                    v.frame,
                    love.graphics.newQuad(v.quad.x, v.quad.y, v.quad.w, v.quad.h, p.texture:getWidth(), p.texture:getHeight())
                )  
                -- print("inserted: " .. v.animation .. " - " .. v.direction .. " - " .. v.frame)
            end                    
        end
    end

    -- setup animation/drawing
    p.animation = "standing"
    p.direction = "left"
    local qx, qy, qw, qh = p.standing.right[1]:getViewport()
    p.offset = qw
    p.offsetX = 0
    p.offsetY = 0
    p.lightoffsetX = p.offset
    p.lightoffsetY = p.offset/2

    -- frame tracker
    p.frametimer = 0
    p.frame = 1

    -- movement timer
    p.movetimer = 0.10
    p.movetimerrate = 0.10      -- temp

    -- bullets and stuff
    p.bullets = {}
    p.bullettimer = 0

    p.light = love.graphics.newImage("assets/lightb.png")

    return p
end

function player:update(dt, dx, dy)
    -- set appropriate animation the player
    if not(dx==0) or not(dy==0) then
        -- set animation as appropriate
        if not(self.animation == "walking") then
            self:setAnimation("walking")
        end

        -- increment the timer
        self.movetimer = self.movetimer - dt
        if self.movetimer <= 0 then
            -- reset timer
            self.movetimer = self.movetimer + self.movetimerrate

            -- get cell of your position
            local px, py = self:getCell()

            -- next cell position
            local nx = px + dx
            local ny = py + dy
            
            -- map/dungeon size
            local mx, my = overworld:getMapSize()

            -- only go forward if the next cell is in bounds
            if nx > 0 and ny > 0 and nx <= mx and ny <= my then
                -- collision check
                local wallcollide, wallcell = overworld:isCollide(nx, ny)
                local doorcollide = overworld:isDoor(nx,ny)
                local keycollide = overworld:isKey(nx,ny)

                -- update if no collision
                if not(wallcollide) and not(doorcollide) then
                    -- update the position
                    self.x = (nx-1) * overworld:getCellSize()
                    self.y = (ny-1) * overworld:getCellSize()
                end
            end
        end
    end

    -- update the animation if necessary
    self.frametimer = self.frametimer + dt
    if self.frametimer >= 0.25 then
        self.frametimer = self.frametimer - 0.25
        self.frame = self.frame + 1
        if self.frame > #self[self.animation][self.direction] then
            self.frame = 1
        end
    end
end

function player:draw()
    -- assign quad
    local q = self[self.animation][self.direction][self.frame]
    love.graphics.draw(self.texture, q, self.x+self.offsetX, self.y+self.offsetY, 0, self.flip, 1)
end

function player:drawLights()
    love.graphics.draw(self.light, self.x+self.lightoffsetX, self.y+self.lightoffsetY, self.angle, 1, 1, 0, self.light:getHeight()/2)
end

function player:setAnimation(a)
    -- set/init animation
    self.animation = a
    self.frame = 1
    self.frametimer = 0
end

function player:setDirection(d)
    -- assign direction, left direction will flip the sideways sprite
    self.direction = d
    self.flip = 1
    self.offsetX = 0
    self.offsetY = 0
    self.lightoffsetX = 0
    self.lightoffsetY = 0
    if d == "right" then
        self.angle = 0
        self.lightoffsetX = self.offset
        self.lightoffsetY = self.offset/2
    elseif d == "down" then
        self.angle = math.pi/2
        self.lightoffsetY = self.offset
    elseif d == "left" then
        self.angle = math.pi
        self.flip = -1
        self.offsetX = self.offset
        self.lightoffsetY = self.offset/2
    elseif d == "up" then
        self.angle = math.pi*3/2    
    end
end

function player:getCell()
    return self.x / overworld:getCellSize() + 1, self.y / overworld:getCellSize() + 1
end

return player
