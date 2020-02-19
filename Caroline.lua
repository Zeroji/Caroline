-- Made to run on 6x4 (61x26) screens
SCREENS = {'monitor_6', 'monitor_7', 'monitor_8'}
SW, SH = 61, 26

-- Multi-screen configuration
M,D={},{}
for i, side in ipairs(SCREENS) do
  m=peripheral.wrap(side)
  m.setBackgroundColor(colors.black)
  m.clear()
  m.setTextScale(1)
  M[i]=m
  D[i]={tab=0}
end

-- Main program configuration
version = '0.5'
timer = 0.2
ltime = 0
running = true
UItw = 9 -- tab width (w/o borders)
UIcx = UItw + 4 -- center panel x
UIcw = SW - UItw - 5 -- center panel width
REcolor = colors.green; TUcolor = colors.cyan; DOcolor = colors.orange; MUcolor = colors.purple
UIcolors = {REcolor, TUcolor, DOcolor, MUcolor}
UIlabels = {' Reactor ', ' Turbine ', '  Doors  ', '  Music  '}

-- Tab config -- Turbine
function TU_Filter(n, obj) return obj.getConnected() end
TUT = {peripheral.find('BigReactors-Turbine', TU_Filter)}
TUop = 38683
TUac = 0.0005
TUautoDefault = true
TUa = {} -- auto
for i in pairs(TUT) do TUa[i] = TUautoDefault end
TUavg = {}
TUsample = 50
TUsptime = TUsample * timer
TUavgr, TUrf, TUavgrf, TUact = 0, 0, 0, 0

-- Tab config -- Music
function MU_AudioFilter(n, obj) return obj.hasAudio() end
MUD = {peripheral.find('drive', MU_AudioFilter)}
MUlen = {["botania:gaia2"]=224, ["botania:gaia1"]=201, ["wanderer"]=287, ["portalgun:records.stillalive"]=174, ["portalgun:records.radioloop"]=22.1, ["portalgun:records.wantyougone"]=141, ["C418 - 13"]=180, ["C418 - cat"]=186, ["C418 - blocks"]=347, ["C418 - chirp"]=186, ["C418 - far"]=172, ["C418 - mall"]=197, ["C418 - mellohi"]=98, ["C418 - stal"]=151, ["C418 - strad"]=191, ["C418 - ward"]=250, ["C418 - 11"]=70}
MUtitle = {["botania:gaia2"]="Kain Vinosec - Fight For Quiescence", ["botania:gaia1"]="Kain Vinosec - Endure Emptiness", ["wanderer"]='Tim Rurkowski - Wanderer', ["portalgun:records.stillalive"]='Valve - Still Alive', ["portalgun:records.radioloop"]='Valve - Radio Loop', ["portalgun:records.wantyougone"]='Valve - Want You Gone'}
MUlyrics = {["portalgun:records.stillalive"]='https://pastebin.com/raw/xvfFcFhK', ["portalgun:records.wantyougone"]='https://pastebin.com/raw/ygLvcqKu'}
MUpl = 0 -- current song
MUtm = 0 -- start time
MUlh, MUln, MUlt, MUlc = nil, '', 0, ''
MUmode = 1 -- play1/loop1/play@/loop@/shuffle@
MUmodeText = {'Play once', 'Loop song', 'Play all ', 'Loop all ', ' Shuffle '}

-- Random functions
function drawUI(m, i, tab) -- draw interface
  if tab==0 then
    m.setBackgroundColor(colors.gray)
  else
    m.setBackgroundColor(UIcolors[tab])
  end
  m.setCursorPos(1, 26)
  m.write(string.rep(' ', 61))
  m.setTextColor(colors.black)
  m.setCursorPos(1, 1)
  local motd='   '..htime()..string.rep(' ', UItw)
  motd=string.sub(motd, 1, UIcx-1)..'Caroline - running version '..version..' on '..SCREENS[i]
  m.write(motd..string.rep(' ', UIcw))
  for yL=2, 25 do
    m.setCursorPos(1, yL); m.write(' ')
    m.setCursorPos(UItw+2, yL); m.write(' ')
    m.setCursorPos(61,yL); m.write(' ')
  end
  
  m.setTextColor(colors.gray)
  for t=1, 4 do
    m.setBackgroundColor(UIcolors[t])
    for yL=1,6 do
      m.setCursorPos(2, t*6-5+yL)
      m.write(string.rep(' ', UItw))
    end
    m.setCursorPos(2, t*6-3)
    m.write(UIlabels[t])
  end
end

function dh(num) -- write stuff like 2M or 96K
  if math.abs(num) < 1000 then return math.floor(num) end
  if math.abs(num) < 1000000 then
    return math.floor(num/1000)..'K'
  else
    return math.floor(num/1000000)..'M'
  end
end

function htime() -- get time in 23:45 format
  local t=os.time()
  h=math.floor(t)
  t=math.floor((t%1)*60)
  return string.format('%02d:%02d', h, t)
end

function hdur(s) -- get durations in 3:45 format
  return string.format('%d:%02d', math.floor(s/60), s%60)
end

function MUstop() -- stop music
  for i, disk in ipairs(MUD) do
    disk.stopAudio()
  end
  MUpl=0
  MUlh, MUln, MUlt, MUlc = nil, '', 0, ''
end

function MUplay(id) -- play stuff
  MUstop()
  if id>table.getn(MUD) then return end
  MUpl=id
  MUD[MUpl].playAudio()
  MUtm=os.clock()
  MUlh=MUlyrics[MUD[MUpl].getAudioTitle()]
  if MUlh ~= nil then
    MUlh = http.get(MUlh)
    os.startTimer(timer*2)
  end
end

function MUlyric()
  if MUlh == nil then return end
  MUlc=MUln
  local line=MUlh.readLine()
  if line == nil then MUlt=999; return end
  MUlt = tonumber(string.sub(line, 1, 6))
  MUln = string.sub(line, 7)
end

function MUrand() MUplay(1+math.floor(math.random()*table.getn(MUD))) end
function MUprev() -- play prev
  if MUpl==0 then return end
  if MUmode==5 then return MUrand() end
  MUplay(math.max(1, MUpl-1))
end
function MUnext()
  if MUmode==5 then return MUrand() end
  MUplay(MUpl+1)
end

function UIclear(m) -- clear main zone
  m.setBackgroundColor(colors.black)
  for yL=2,25 do
    m.setCursorPos(UIcx-1, yL)
    m.write(string.rep(' ',UIcw+2))
  end
end

-- Main loop
os.startTimer(timer)
while running do
  event, eside, x, y = os.pullEvent()
  if event=='timer' or os.clock()-ltime>=timer then
    ltime=os.clock()
    os.startTimer(timer)
  end
  
  -- Turbine loop
  TUavgr, TUrf, TUact = 0, 0, 0
  for i, t in ipairs(TUT) do
    local rpm = t.getRotorSpeed()
    if TUa[i] then -- auto
      if rpm > (1+TUac)*TUop then
        t.setActive(false)
        t.setInductorEngaged(true)
      elseif rpm < (1-TUac)*TUop then
        t.setActive(true)
        t.setInductorEngaged(false)
      else
        t.setActive(true)
        if rpm>=TUop then
          t.setInductorEngaged(true)
        end
      end
    end
    TUavgr = TUavgr + rpm
    TUrf = TUrf + t.getEnergyProducedLastTick()
    if t.getInductorEngaged() then TUact = TUact+1 end
  end
  if event=='timer' then
    TUavgrf=0
    table.insert(TUavg, TUrf)
    if table.getn(TUavg) > TUsample then table.remove(TUavg, 1) end
    for i, x in ipairs(TUavg) do TUavgrf = TUavgrf + x end
    TUavgrf = TUavgrf / table.getn(TUavg)
  end
  TUavgr = TUavgr / table.getn(TUT)

  -- Music loop
  local MUid, MUl
  if MUpl>0 then
    MUid=MUD[MUpl].getAudioTitle()
    if MUlen[MUid] ~= nil then MUl=MUlen[MUid] else MUl=599 end
    if os.clock() >= MUtm+MUl then
      if MUmode == 1 then
        MUstop()
      elseif MUmode == 2 then
        MUplay(MUpl)
      else
        MUnext()
        if MUmode == 4 and MUpl==0 then MUnext() end
      end
    elseif MUlh~= nil and os.clock()-MUtm > MUlt then
      MUlyric()
    end
  end

  -- UI
  for i, m in ipairs(M) do
    d=D[i]
    drawUI(m, i, d.tab)
    -- Tab details
    if TUact > 0 then
      m.setBackgroundColor(TUcolor)
      m.setTextColor(colors.gray)
      m.setCursorPos(5, 11)
      m.write(TUact..'/'..table.getn(TUT))
      m.setCursorPos(3, 12)
      m.write(dh(TUavgrf).. ' RF/t')
    end
    
    if MUpl > 0 then
      m.setBackgroundColor(MUcolor)
      m.setTextColor(colors.gray)
      m.setCursorPos(3, 23)
      m.write('playing')
      m.setCursorPos(2, 24)
      name=MUD[MUpl].getAudioTitle()
      if MUtitle[name] ~= nil then name=MUtitle[name] end
      name = string.rep(' ', UItw-1)..name
      shift = math.floor(os.clock()*2.5)%string.len(name)
      m.write(string.sub(name, shift+1, shift+UItw))
    end
    
    if d.tab == 2 then -- Turbine UI
      m.setBackgroundColor(colors.black)
      for i, t in ipairs(TUT) do -- turbine list
       m.setTextColor(t.getActive() and TUcolor or colors.gray)
       m.setCursorPos(UIcx, i+2)
       m.write(string.format('Turbine #%02d', i))
       m.setTextColor(TUa[i] and TUcolor or colors.gray)
       m.write(TUa[i] and ' AUTO' or ' ----')
       local rpc, rpm = colors.blue, t.getRotorSpeed()
       if rpm>=0.5*TUop then rpc=colors.light_blue end
       if rpm>=0.8*TUop then rpc=colors.green end
       if rpm>=(1-TUac)*TUop then rpc=colors.lime end
       if rpm>=(1+TUac)*TUop then rpc=colors.yellow end
       if rpm>=1.2*TUop then rpc=colors.orange end
       if rpm>1.5*TUop then rpc=colors.red end
       m.setTextColor(rpc)
       m.setCursorPos(UIcx+UIcw/2-3, i+2)
       m.write(string.format('%7d RPM', rpm))
       m.setCursorPos(SW-13, i+2)
       if t.getInductorEngaged() then
         m.setTextColor(TUcolor)
         m.write(string.format('%7d RF/t', t.getEnergyProducedLastTick()))
       else
         m.setTextColor(colors.gray)
         m.write('[Disengaged]')
       end
      end
      m.setCursorPos(UIcx, 22)
      m.setTextColor(colors.gray)
      m.write('Average RPM: ')
      m.setTextColor(TUcolor)
      m.write(string.format('%d    ', TUavgr))
      m.setCursorPos(UIcx, 23)
      m.setTextColor(colors.gray)
      m.write('Average energy produced: ')
      m.setTextColor(TUcolor)
      m.write(string.format('%d RF/t       ', TUrf))
      m.setCursorPos(UIcx, 24)
      m.setTextColor(colors.gray)
      m.write(string.format('Over the last %d seconds: ', TUsptime))
      m.setTextColor(TUcolor)
      m.write(string.format('%d RF/t       ', TUavgrf))
    elseif d.tab == 4 then -- Music UI
      for i, disk in ipairs(MUD) do -- songlist
        local id, name, len
        id=disk.getAudioTitle()
        if MUtitle[id] ~= nil then name=MUtitle[id] else name=id end
        if MUlen[id] ~= nil then len=MUlen[id] else len=599 end
        m.setCursorPos(UIcx, i+2)
        if i==MUpl then
          m.setBackgroundColor(MUcolor)
        else
          m.setBackgroundColor(colors.black)
        end
        s=string.sub(name..string.rep(' ', UIcw),1,UIcw-4)..string.format('%5s', hdur(len))
        m.write(s)
      end
      -- bottom area
      if MUpl == 0 then
        m.setBackgroundColor(colors.black)
        for yL=21,25 do
          m.setCursorPos(UIcx, yL)
          m.write(string.rep(' ', UIcw))
        end
      else
        local MUtime = (os.clock()-MUtm)
        local MUcur = math.floor(MUtime*UIcw/MUl)
        m.setTextColor(MUcolor)
        m.setBackgroundColor(colors.black)
        m.setCursorPos(UIcx, 23)
        m.write(hdur(MUtime))
        m.setCursorPos(UIcx+UIcw-4, 23)
        m.write(string.format('%5s', hdur(MUl)))
        local lpad=string.rep(' ', (UIcw-string.len(MUlc))/2)
        m.setCursorPos(UIcx, 21)
        m.write(lpad..MUlc..lpad)
        m.setCursorPos(UIcx+UIcw/2-7, 23)
        m.write('<< ')
        m.write(MUmodeText[MUmode])
        m.write(' >>')
        m.setTextColor(colors.gray)
        lpad=string.rep(' ', (UIcw-string.len(MUln))/2)
        m.setCursorPos(UIcx, 22)
        m.write(lpad..MUln..lpad)
        m.setBackgroundColor(colors.gray)
        m.setCursorPos(UIcx, 24)
        m.write(string.rep(' ', UIcw))
        m.setBackgroundColor(MUcolor)
        m.setCursorPos(UIcx+MUcur, 24)
        m.write(' ')
      end
    end
    
    if event=="monitor_touch" and eside==SCREENS[i] then
      -- touchy stuffy
      if x*y==1 then running=false end -- quit
      if x==1 or x==SW or y==1 or y==SH then d.tab=0 UIclear(m) end -- frame click
      if x>=2 and x<UItw+2 and y>1 and y<SH then
        d.tab = math.floor((y+4)/6)
        UIclear(m)
      end
      if x>=UIcx-1 and x<SW and y>1 and y<SH then
        if d.tab==2 then -- touchy the spinny
          if y>2 and y<3+table.getn(TUT) then
            local t=TUT[y-2]
            if x>=UIcx and x<UIcx+11 then
              t.setActive(not t.getActive())
              TUa[y-2]=false
            elseif x>UIcx+11 and x<UIcx+16 then
              TUa[y-2]=not TUa[y-2]
            elseif x>=SW-13 and x<SW-1 then
              t.setInductorEngaged(not t.getInductorEngaged())
              TUa[y-2]=false
            end
          end
        elseif d.tab==4 then -- touchy the soundy
          if y>2 and y<3+table.getn(MUD) then
            if MUpl==y-2 then MUstop() else MUplay(y-2) end
          end
          if y==23 then
            local mid=math.floor(UIcx+UIcw/2)
            if math.abs(mid-x)<=4 then
              MUmode=MUmode%5+1
            elseif x>=mid-7 and x<mid then
              MUprev()
            elseif x<=mid+7 and x>mid then
              MUnext()
            end
          end
        end
      end
    end
  end
end
for i, m in ipairs(M) do
  m.setBackgroundColor(colors.black)
  m.clear()
end
