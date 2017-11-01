local module = {
  data = {},
}

local getSetting = function(label, default) 
  return hs.settings.get(label)
  or 
  default 
end

local serverURL = getSetting("squeezeconfig").serverURL
local playerId = getSetting("squeezeconfig").playerId

local log = function(t)
  print(hs.inspect.inspect(t))
end

function module:setData(data)
  if data.error then
    module.data = data
  else
    local curr = data.playlist_loop[tonumber(data.playlist_cur_index)+1]

    module.data = {current=curr,
    		   raw=data,
    }
    log(module.data)
  end
  self:draw()
end

function module:parseJson(s,r,h)
  --if s == 200 then
    module:setData(hs.json.decode(s).result)
  --else
  --  module:setData({error="Error from server"})
  --end
end

function module:get ()
  hs.http.asyncPost(serverURL .. "jsonrpc.js", '{"id":1,"method":"slim.request","params":["' .. playerId .. '",["status","0","999","tags:Jyaild"]]}', nil, module.parseJson)
end

function module:request(cmd)
  print(cmd)
  hs.http.asyncPost(serverURL .. "jsonrpc.js", '{"id":1,"method":"slim.request","params":["' .. playerId .. '",'..cmd..']}', nil, print)
end

function module:draw()
  module.menubar:setTitle("🎶")
  local menuitems = {}

  if (module.data and module.data.error) then
    table.insert(menuitems, {title="Error connecting, check config", disabled=true})
  elseif (module.data and module.data.current) then
    local modelang = {["stop"] = "stopped",
                      ["play"] = "playing",
                      ["pause"] = "paused",
    }
	
    local current = module.data.current
    local raw = module.data.raw
    
    table.insert(menuitems, {title=modelang[raw.mode], disabled=true})
    table.insert(menuitems, {title=string.sub(current.title,0, 26), disabled=true})
    table.insert(menuitems, {title=string.sub(current.artist,0, 26), disabled=true})
    table.insert(menuitems, {title=string.sub(current.album,0, 26), disabled=true})
    table.insert(menuitems, {title=math.floor(raw.time/60)..":"..math.fmod(math.floor(raw.time),60).."/"..
                                   math.floor(current.duration/60)..":"..math.fmod(math.floor(current.duration),60), disabled=true})
    --table.insert(menuitems, {image=, disabled=true})
    table.insert(menuitems, {title="-"})

    if module.data.raw.mode == "play" then
      table.insert(menuitems, {title="Pause", fn=function() module:request('["pause","1"]') end})
    else
      table.insert(menuitems, {title="Play", fn=function() module:request('["play","0"]') end})
    end
    table.insert(menuitems, {title="Next"})
    table.insert(menuitems, {title="Previous"})
  else
    table.insert(menuitems, {title="Not connected", disabled = true})
  end

  module.menubar:setMenu(menuitems)
end

function module:init()
  module.menubar = hs.menubar.new()
  self.draw()
  self.get()
  module.timer = hs.timer.doEvery(2, self.get)
end

return module
