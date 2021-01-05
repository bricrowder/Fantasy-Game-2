local overworld = {}
overworld.__index = overworld

function overworld.new()
    local o = {}
    setmetatable(o, overworld)

    -- variable for random generation
    local a = math.random(config.overworld.terrainRand)
    local b = math.random(config.overworld.terrainRand)                    
    local c = math.random(config.overworld.objectRand)
    local d = math.random(config.overworld.objectRand)    

    -- lists for the world
    o.map = {}
    o.objects = {}
    o.dungeons = {}
    o.dlocations = {}
    o.lights = {} -- remove

    -- init the objects list
    o.objects.spritebatch = {}
    for i=1, 3 do
        o.objects.spritebatch[i] = love.graphics.newSpriteBatch(objects.texture)
    end


    -- temp terrain sprites
    -- need to be put into a json file
    o.terraintex = love.graphics.newImage("assets/terrain2.png")
    o.rock = {
        corner = love.graphics.newQuad(0,0,32,32,256,256),
        wall = love.graphics.newQuad(0,32,32,32,256,256),
        deadend = love.graphics.newQuad(0,64,32,32,256,256),
        centre = love.graphics.newQuad(0,96,32,32,256,256)
    }
    o.forest = {
        corner = love.graphics.newQuad(32,0,32,32,256,256),
        wall = love.graphics.newQuad(32,32,32,32,256,256),
        deadend = love.graphics.newQuad(32,64,32,32,256,256),
        centre = love.graphics.newQuad(32,96,32,32,256,256)
    }
    o.grass = {
        corner = love.graphics.newQuad(64,0,32,32,256,256),
        wall = love.graphics.newQuad(64,32,32,32,256,256),
        deadend = love.graphics.newQuad(64,64,32,32,256,256),
        centre = love.graphics.newQuad(64,96,32,32,256,256)        
    }
    o.beach = {
        corner = love.graphics.newQuad(96,0,32,32,256,256),
        wall = love.graphics.newQuad(96,32,32,32,256,256),
        deadend = love.graphics.newQuad(96,64,32,32,256,256),
        centre = love.graphics.newQuad(96,96,32,32,256,256)
    }

    o.dungeonentrance = {
        rock = love.graphics.newQuad(128,0,64,64,256,256)
    }

    o.terrain = love.graphics.newSpriteBatch(o.terraintex)



    -- randomly generate terrain based on noise
    for i = 1, config.overworld.width do
        o.map[i] = {}
        for j = 1, config.overworld.height do
            -- terrain/light value
            local n = love.math.noise(i/config.overworld.terrainFreq, j/config.overworld.terrainFreq, a/config.overworld.terrainFreq)
            o.map[i][j] = nil

            -- set terrain biome based on noise value
            for k, v in ipairs(config.overworld.terrain) do
                if n >= v.min and n < v.max then
                    o.map[i][j] = {biome = v.biome, colour = v.colour, var=v.variation, wall=false, obj=false}
                end
            end

            -- set lights beside the roads
            for k, v in ipairs(config.overworld.lights) do
                if n >= v.min and n <= v.max and math.random() <= v.rate then
                    -- create with light name and world pos
                    table.insert(o.lights, light_class.new(v.light, (i-1)*config.overworld.cellSize, (j-1)*config.overworld.cellSize, 0))
                end
            end
        end
    end 

    for i = 1, config.overworld.width do
        for j = 1, config.overworld.height do
            -- temp
            local q = nil
            local c = {
                n = false,
                e = false,
                s = false,
                w = false,
                count = 0
            }
            -- what is around it?
            if i > 1 and o.map[i-1][j].biome ~= o.map[i][j].biome then
                -- determine which biome
                local b1 = o.map[i][j].biome
                local b2 = o.map[i-1][j].biome

                if (b1 == "beach" and b2 == "water") or 
                (b1 == "grass" and b2 == "beach") or 
                (b1 == "forest" and b2 == "grass") or 
                (b1 == "rock" and b2 == "forest") then
                    c.w = true
                    c.count = c.count + 1
                end
            end 
            if i < config.overworld.width and o.map[i+1][j].biome ~= o.map[i][j].biome then
                -- determine which biome
                local b1 = o.map[i][j].biome
                local b2 = o.map[i+1][j].biome

                if (b1 == "beach" and b2 == "water") or 
                (b1 == "grass" and b2 == "beach") or 
                (b1 == "forest" and b2 == "grass") or 
                (b1 == "rock" and b2 == "forest") then
                    c.e = true
                    c.count = c.count + 1
                end
            end             
            if j > 1 and o.map[i][j-1].biome ~= o.map[i][j].biome then
                -- determine which biome
                local b1 = o.map[i][j].biome
                local b2 = o.map[i][j-1].biome

                if (b1 == "beach" and b2 == "water") or 
                (b1 == "grass" and b2 == "beach") or 
                (b1 == "forest" and b2 == "grass") or 
                (b1 == "rock" and b2 == "forest") then                
                    c.n = true
                    c.count = c.count + 1
                end
            end 
            if j < config.overworld.height and o.map[i][j+1].biome ~= o.map[i][j].biome then
                -- determine which biome
                local b1 = o.map[i][j].biome
                local b2 = o.map[i][j+1].biome

                if (b1 == "beach" and b2 == "water") or 
                (b1 == "grass" and b2 == "beach") or 
                (b1 == "forest" and b2 == "grass") or 
                (b1 == "rock" and b2 == "forest") then                
                    c.s = true
                    c.count = c.count + 1
                end
            end 

            local a = 0
            if c.count == 1 then
                -- its a wall, what direction?
                if c.e then
                    a = 0
                elseif c.s then
                    a = math.pi/2
                elseif c.w then
                    a = math.pi
                elseif c.n then
                    a = math.pi*3/2
                end
                -- what biome?
                if o.map[i][j].biome == "beach" then
                    q = o.beach.wall
                elseif o.map[i][j].biome == "grass" then
                    q = o.grass.wall
                elseif o.map[i][j].biome == "forest" then
                    q = o.forest.wall
                elseif o.map[i][j].biome == "rock" then
                    q = o.rock.wall
                elseif o.map[i][j].biome == "water" then
                elseif o.map[i][j].biome == "road" then
                else
                    print("no matching biome: " .. i .. "," .. j .. " - " .. o.map[i][j].biome)
                end
            elseif c.count == 2 then
                -- its a corner, what direction?
                if c.n and c.e then
                    a = 0
                elseif c.e and c.s then
                    a = math.pi/2
                elseif c.s and c.w then
                    a = math.pi
                elseif c.w and c.n then
                    a = math.pi*3/2
                end
                -- what biome?
                if o.map[i][j].biome == "beach" then
                    q = o.beach.corner
                elseif o.map[i][j].biome == "grass" then
                    q = o.grass.corner
                elseif o.map[i][j].biome == "forest" then
                    q = o.forest.corner
                elseif o.map[i][j].biome == "rock" then
                    q = o.rock.corner
                elseif o.map[i][j].biome == "water" then
                elseif o.map[i][j].biome == "road" then
                else
                    print("no matching biome: " .. i .. "," .. j .. " - " .. o.map[i][j].biome)
                end                
            elseif c.count == 3 then
                -- its a deadend, what direction?
                if not(c.w) then
                    a = 0
                elseif not(c.n) then
                    a = math.pi/2
                elseif not(c.e) then
                    a = math.pi
                elseif not(c.s) then
                    a = math.pi*3/2
                end
                -- what biome?
                if o.map[i][j].biome == "beach" then
                    q = o.beach.deadend
                elseif o.map[i][j].biome == "grass" then
                    q = o.grass.deadend
                elseif o.map[i][j].biome == "forest" then
                    q = o.forest.deadend
                elseif o.map[i][j].biome == "rock" then
                    q = o.rock.deadend
                elseif o.map[i][j].biome == "water" then
                elseif o.map[i][j].biome == "road" then
                else
                    print("no matching biome: " .. i .. "," .. j .. " - " .. o.map[i][j].biome)                
                end
            elseif c.count == 0 or c.count == 4 then
                -- what biome?
                if o.map[i][j].biome == "beach" then
                    q = o.beach.centre
                elseif o.map[i][j].biome == "grass" then
                    q = o.grass.centre
                elseif o.map[i][j].biome == "forest" then
                    q = o.forest.centre
                elseif o.map[i][j].biome == "rock" then
                    q = o.rock.centre
                elseif o.map[i][j].biome == "water" then
                elseif o.map[i][j].biome == "road" then
                else
                    print("no matching biome: " .. i .. "," .. j .. " - " .. o.map[i][j].biome)
                end                
            end

            -- this issue is the orientation/rotation of the quads.... sort that out!

            if q then
                o.terrain:add(q, (i-1)*config.overworld.cellSize+config.overworld.cellSize/2, (j-1)*config.overworld.cellSize+config.overworld.cellSize/2, a, 1, 1, config.overworld.cellSize/2, config.overworld.cellSize/2)
            end
        end
    end

    -- print("Terrain Textures: " .. o.terrain:getCount())

    -- randomly generate objects
    for i = 1, config.overworld.width do
        for j = 1, config.overworld.height do
            -- only put an object there if it isn't already taken up
            if not(o.map[i][j].obj) then
                -- generate object noise value
                local t = love.math.noise(i/config.overworld.objectFreq, j/config.overworld.objectFreq, c/config.overworld.objectFreq, d/config.overworld.objectFreq)

                -- see what object could belong here: by noise value
                for k, v in ipairs(config.overworld.objects) do
                    if t >= v.min and t <= v.max then
                        local inBiome = false
                        for b, c in ipairs(v.biome) do
                            if c == o.map[i][j].biome then
                                inBiome = true
                                break
                            end
                        end

                        -- get max size from this point, starting with a size of one (the one you are on), just go right/down for ease
                        -- CHANGE TO A CONFIG VALUE
                        local max = 1
                        for c=1, 3 do
                            if i+c <= config.overworld.width and not(o.map[i+c][j].obj) and j+c <= config.overworld.height and not(o.map[i][j+c].obj) then
                                max = max + 1
                            else
                                break
                            end
                        end
                        -- by biome
                        if inBiome then
                            -- get a list of quads that fit in the max and is the type of obj we are looking for
                            local objQuadList = {}
                            local l = 0
                            for b, c in ipairs(objects.info) do
                                if c.cellSize <= max and c.category == v.category then
                                    table.insert(objQuadList, c.quad)
                                    l = c.layer
                                end
                            end

                            -- randomly pick a quad
                            local q = objQuadList[math.random(#objQuadList)]

                            -- randomly pick a layer if necessary
                            if l == 0 then
                                l = math.random(#o.objects.spritebatch)
                            end

                            -- create the object
                            -- YOU SHOULD CAPTURE THE INDEX AND CREATE AN object OF SOME TYPE SO YOU CAN MOVE IT AROUND AND STUFF
                            o.objects.spritebatch[l]:add(q, (i-1)*config.overworld.cellSize, (j-1)*config.overworld.cellSize)

                            -- set the walls based on the quad size in cells
                            local qx, qy, qw, qh = q:getViewport()
                            local w = qw / config.overworld.cellSize

                            -- mark the objects
                            for b=0, w-1 do
                                for c=0, w-1 do
                                    o.map[i+b][j+c].obj = true
                                end
                            end
                            -- table.insert(o.objects, {ix=i, iy=j, colour={0,1,0,1}, texture = nil})     
                            -- o.trees:add(i*config.overworld.cellSize, j*config.overworld.cellSize)
                        end
                    end
                end        
            end
        end
    end

    -- create a random number of dungeons
    local d = math.random(config.overworld.dungeonMin, config.overworld.dungeonMax)
    for i = 1, d do
        -- determine size
        -- local s = math.random(4,config.dungeon.width)
        local w = math.random(4,config.dungeon.width)
        local h = math.random(4,config.dungeon.height)
        -- local w = 4
        -- local h = 4

        -- pick a random location, remove some border to accomodate dungeon entrances larger than one cell... just and easy way to do this
        table.insert(o.dlocations, {
            i=math.random(1,config.overworld.width-4),    
            j=math.random(1,config.overworld.height-4),
            x=0,
            y=0,
            index=i
        })
        o.dlocations[#o.dlocations].x = (o.dlocations[#o.dlocations].i-1) * config.overworld.cellSize
        o.dlocations[#o.dlocations].y = (o.dlocations[#o.dlocations].j-1) * config.overworld.cellSize
        o.dlocations[#o.dlocations].size = 2
        o.map[o.dlocations[#o.dlocations].i][o.dlocations[#o.dlocations].j].wall = true
        o.map[o.dlocations[#o.dlocations].i+1][o.dlocations[#o.dlocations].j].wall = true
        o.map[o.dlocations[#o.dlocations].i][o.dlocations[#o.dlocations].j+1].wall = true
        o.map[o.dlocations[#o.dlocations].i+1][o.dlocations[#o.dlocations].j+1].wall = true

        -- need to mark the overworld cells so the player can't collide with the entrance... 
        print("dungeon: " .. o.dlocations[#o.dlocations].i, o.dlocations[#o.dlocations].j)

        -- create dungeon
        table.insert(o.dungeons, dungeon_class.new(w,h,o.dlocations[#o.dlocations].i, o.dlocations[#o.dlocations].j))

        -- setup the dungeon
        o.dungeons[#o.dungeons]:getpaths()
        o.dungeons[#o.dungeons]:setDoorsandKeys()
        o.dungeons[#o.dungeons]:bake()
        o.dungeons[#o.dungeons]:setCells()

    end
    
    -- init the current dungeon
    o.currentDungeon = 1

    -- bake the overworld into a texture
    o.texture = love.graphics.newCanvas(config.overworld.width, config.overworld.height)
    love.graphics.setCanvas(o.texture)

    for i=1, config.overworld.width do
        for j=1, config.overworld.height do
            local c = {
                o.map[i][j].colour[1] + math.random(-1,1) * o.map[i][j].var[1],
                o.map[i][j].colour[2] + math.random(-1,1) * o.map[i][j].var[2],
                o.map[i][j].colour[3] + math.random(-1,1) * o.map[i][j].var[3],
                o.map[i][j].colour[4] + math.random(-1,1) * o.map[i][j].var[4]
            }
            love.graphics.setColor(c)
            love.graphics.rectangle("fill", i-1, j-1, 1, 1)
        end
    end

    love.graphics.setColor(1,1,1,1)

    love.graphics.setCanvas()

    -- bake the overworld into a minimap texture
    o.minimap = love.graphics.newCanvas(config.overworld.minimapWidth, config.overworld.minimapHeight)
    love.graphics.setCanvas(o.minimap)
    love.graphics.draw(o.texture,0,0,0,o.minimap:getWidth()/o.texture:getWidth(), o.minimap:getHeight()/o.texture:getHeight())
    love.graphics.setCanvas()
    
    -- time 
    o.timer = 0
    o.timecolour = config.overworld.time.night

    return o
end

function overworld:update(dt)
    if mode == "overworld" then
        -- anything to update??
    elseif mode == "dungeon" then
        self.dungeons[self.currentDungeon]:update(dt)  
    end

    -- update the day/night cycle
    self.timer = self.timer + dt

    if self.timer >= config.overworld.time.length then
        self.timer = self.timer - config.overworld.time.length
        if self.timecolour == config.overworld.time.day then
            self.timecolour = config.overworld.time.night
        else
            self.timecolour = config.overworld.time.day
        end
    end   

end

function overworld:draw()
    if mode == "overworld" then
        -- draw the texture based on the cellsize
        love.graphics.draw(self.texture, 0, 0, 0, config.overworld.cellSize, config.overworld.cellSize)
        love.graphics.draw(self.terrain, 0, 0)
        for i, v in ipairs(self.dlocations) do
            love.graphics.draw(self.terraintex, self.dungeonentrance.rock, v.x, v.y)
        end
        for i, v in ipairs(self.lights) do
            love.graphics.circle("fill", v.x, v.y, 16)
        end

        love.graphics.setColor(1,0,0,1)
        for i, v in ipairs(self.dlocations) do
            love.graphics.circle("fill", v.x*config.overworld.cellSize, v.y*config.overworld.cellSize, 32)
        end
    
        love.graphics.setColor(1,1,1,1)


        -- love.graphics.draw(self.trees, 0,0)
        -- for k, v in ipairs(self.objects) do
        --     love.graphics.circle("fill", v.ix*config.overworld.cellSize, v.iy*config.overworld.cellSize, 8)
        -- end        
    elseif mode == "dungeon" then
        self.dungeons[self.currentDungeon]:draw()
    end
    love.graphics.setColor(1,1,1,1)
    
end

function overworld:drawObjects(i)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(self.objects.spritebatch[i], 0, 0)
end

function overworld:drawLights()
    if mode == "overworld" then
        for i, v in ipairs(self.lights) do
            v:draw()
        end
    elseif mode == "dungeon" then
        self.dungeons[self.currentDungeon]:drawLights()
    end
end

function overworld:getCell(x, y)
    if mode == "overworld" then
        -- return the overworld cell based on the provided world position
        return math.floor(x / config.overworld.cellSize) + 1, math.floor(y / config.overworld.cellSize) + 1
    elseif mode == "dungeon" then
        return math.floor(x / config.room.cellSize) + 1, math.floor(y / config.room.cellSize) + 1
    end
end

function overworld:isCollide(ix, iy)
    local collide = false
    local rect = {
        x1=0,
        y1=0,
        x2=0,
        y2=0
    }
    if mode == "overworld" then
        if self.map[ix][iy].wall then
            rect.x1 = (ix-1) * config.overworld.cellSize
            rect.y1 = (iy-1) * config.overworld.cellSize
            rect.x2 = rect.x1 + config.overworld.cellSize
            rect.y2 = rect.y1 + config.overworld.cellSize
            return true, rect
        end
    elseif mode == "dungeon" then
        if self.dungeons[self.currentDungeon].cells[ix][iy].wall then
            rect.x1 = (ix-1) * config.room.cellSize
            rect.y1 = (iy-1) * config.room.cellSize
            rect.x2 = rect.x1 + config.room.cellSize
            rect.y2 = rect.y1 + config.room.cellSize
            return true, rect
        end
    end
    return false
end

function overworld:getDimensions()
    local w, h = 0, 0

    if mode == "overworld" then
        w = config.overworld.width * config.overworld.cellSize
        h = config.overworld.height * config.overworld.cellSize
    elseif mode == "dungeon" then
        w = self.dungeons[self.currentDungeon].width * config.room.width * config.room.cellSize
        h = self.dungeons[self.currentDungeon].height * config.room.height * config.room.cellSize
    end

    return w, h
end

function overworld:getMapSize()
    if mode == "overworld" then
        return config.overworld.width, config.overworld.height 
    elseif mode == "dungeon" then
        return #self.dungeons[self.currentDungeon].cells, #self.dungeons[self.currentDungeon].cells[1] 
    end
end

function overworld:getAmbientColour()
    if mode == "overworld" then
        return self.timecolour
    elseif mode == "dungeon" then
        return self.dungeons[self.currentDungeon].ambient
    end
end

function overworld:getCellSize()
    if mode == "overworld" then
        return config.overworld.cellSize
    elseif mode == "dungeon" then
        return config.room.cellSize
    end
end

function overworld:atEntrance(x, y)
    -- need to incorporate the size of the dungeon entrances and exits...  some are 64, some are 32... 
    if mode == "overworld" then
        -- entrances can NEVER be in first/last row & column... so we can always check in -1, +1 without out of bounds issues
        for i, v in ipairs(self.dlocations) do
            local x1 = v.i-1
            local x2 = v.i + v.size
            local y1 = v.j-1
            local y2 = v.j + v.size
            if x >= x1 and x <= x2 and y >= y1 and y <= y2 then
                self.currentDungeon = v.index
                mode = "dungeon"
                player.x = self.dungeons[self.currentDungeon].entrance.x
                player.y = self.dungeons[self.currentDungeon].entrance.y + config.room.cellSize
            end
        end
    elseif mode == "dungeon" then
        -- change this to a player input based check... player gets in range, prompts entry, plyer presses button
        if (x == self.dungeons[self.currentDungeon].entrance.i and y == self.dungeons[self.currentDungeon].entrance.j) or (x == self.dungeons[self.currentDungeon].exit.i and y == self.dungeons[self.currentDungeon].exit.j) then
            mode = "overworld"
            player.x = self.dungeons[self.currentDungeon].ret.x
            player.y = self.dungeons[self.currentDungeon].ret.y + config.room.cellSize
        end
    end
end

function overworld:isDoor(x, y)
    if mode == "dungeon" then
        if self.dungeons[self.currentDungeon].cells[x][y].door > 0 then
            -- is the door NOT open?
            if self.dungeons[self.currentDungeon].doors[self.dungeons[self.currentDungeon].cells[x][y].door].closed then
                return true
            end
        end
        return false
    end
    return false
end

function overworld:isKey(x, y)
    if mode == "dungeon" then
        for i, v in ipairs(self.dungeons[self.currentDungeon].keys) do
            if not(v.taken) and v.i == x and v.j == y then
                -- mark that the key has been taken
                v.taken = true
                print("have key!")
                return true
            end
        end
    end
    return false
end

function overworld:openDoor(x,y,d)
    -- check if there is a door around the player
    -- if there is, what door is it?
    -- check if that key has been taken
    -- yes: then open!
    -- no: do nothing
    local i = x
    local j = y
    print(d)

    if mode == "dungeon" then
        -- check in the direction but consider bounds fo the map
        if d == "right" and not(x == #self.dungeons[self.currentDungeon].cells) then
            i = x+1 
        elseif d == "left" and not(x == 1) then
            i = x-1 
        elseif d == "down" and not(y == #self.dungeons[self.currentDungeon].cells[1]) then
            j = y+1 
        elseif d == "up" and not(y == 1) then
            j = y-1
        else
            return
        end

        if self.dungeons[self.currentDungeon].cells[i][j].door > 0 and self.dungeons[self.currentDungeon].keys[self.dungeons[self.currentDungeon].cells[i][j].door].taken then
            self.dungeons[self.currentDungeon].doors[self.dungeons[self.currentDungeon].cells[i][j].door].closed = false
        end
    end
end

return overworld