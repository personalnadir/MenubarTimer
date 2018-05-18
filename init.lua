--- === TimeBar ===
---
--- A visual timer which is drawn over the MacOS menubar.
--- The timer is controlled using URLs.
--- hammerspoon://timebar?minutes=2
--- TimeBar accepts second[s], minute[s] and hour[s] as parameters and can be
--- mixed such as hammerspoon://timebar?hour=1&minutes=2&seconds=30
--- TimeBar:start() must be called to start listening for URLs
--- TimeBar:stop() can be called to cease the listening

function stopPreviousBar()
  if timeBarRect then
    timeBarRect:delete()
  end
  if timeBarAnimate then
    timeBarAnimate:stop()
  end
end

function timeBar(duration)
  stopPreviousBar()
  local screen=hs.screen.mainScreen()
  local frame=screen:fullFrame()
  local menuh=frame.h-screen:frame().h
  local width=frame.w
  local rightCol={red=0.98,green=0.361,blue=0.49,alpha=0.5}
  local leftCol={red=0.416,green=0.51,blue=0.981,alpha=0.5}

  timeBarRect=hs.drawing.rectangle(hs.geometry.rect(0,0,width,menuh))
  timeBarRect:setFill(true)
  timeBarRect:setBehaviorByLabels({hs.drawing.windowBehaviors.canJoinAllSpaces})
  timeBarRect:show()

  local function generateRectangle(endCol)
    timeBarRect:setSize({w=width,h=menuh})
    timeBarRect:setFillGradient(leftCol,endCol,0)
  end
  generateRectangle(rightCol)

  local function interpolate(startCol,endCol,ratio)
    local newCol={}

    for k,v in pairs(startCol) do
      local dv=endCol[k]-v
      newCol[k]=v+dv*ratio
    end

    return newCol
  end

  local step=duration/width
  local startNS=hs.timer.absoluteTime()
  timeBarAnimate=hs.timer.doUntil(function() return width==0 end, function()
    local curNS=hs.timer.absoluteTime()
    local ratio=1-(curNS-startNS)/(duration*1e9)
    width=math.max(0,frame.w*ratio)
    generateRectangle(interpolate(leftCol,rightCol,ratio))
  end,step)

  timeBarAnimate:start()
end

function startListening()
  hs.urlevent.bind("timebar", function(_, params)
    local seconds=0
    local fieldsToSeconds={
      second=1,
      seconds=1,
      minute=60,
      minutes=60,
      hour=60*60,
      hours=60*60
    }
    for k,v in pairs(fieldsToSeconds) do
      if params[k] then
        seconds=seconds+params[k]*v
      end
    end
    if seconds==0 then
      hs.alert.show("timebar duration not specified")
    else
      timeBar(seconds)
    end
  end)
end

function stopListening()
  stopPreviousBar()
  hs.urlevent.bind("timebar", nil)
end

return {
  name='TimeBar',
  version=1,
  author='Tom Piercy',
  licence='MIT',
  start=startListening,
  stop=stopListening
}