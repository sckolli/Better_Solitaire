io.stdout:setvbuf("no")
require "card"
require "grabber"
require "pile"
require "deck"
local CardAssets = require("card_assets")
local Buttons    = require("buttons")

CARD_WIDTH        = 73
CARD_HEIGHT       = 97
CARD_OVERLAP      = 25
ANIMATION_SPEED   = 0.2
DOUBLE_CLICK_TIME = 0.5

buttons = {
  reset = { x=800, y=10, w=70, h=30, label="Reset" },
  undo  = { x=720, y=10, w=70, h=30, label="Undo"  }
}


history = {}


local function serializePile(p)
  local out = { x=p.x, y=p.y, type=p.type, index=p.index, cards={} }
  for i, c in ipairs(p.cards) do
    out.cards[i] = {
      suit   = c.suit,
      value  = c.value,
      faceUp = c.faceUp,
      x      = c.x,
      y      = c.y
    }
  end
  return out
end

local function serializePiles(piles)
  local out = {}
  for key, val in pairs(piles) do
    if val.type then
      out[key] = serializePile(val)
    else
      out[key] = {}
      for i, pile in ipairs(val) do
        out[key][i] = serializePile(pile)
      end
    end
  end
  return out
end

local function restorePile(saved)
  local p = PileClass:new(saved.x, saved.y, saved.type, saved.index)
  for _, info in ipairs(saved.cards) do
    local c = CardClass:new(info.suit, info.value)
    c.x, c.y = info.x, info.y
    if info.faceUp then c:flip() end
    p:addCard(c)
  end
  return p
end

local function restorePiles(saved)
  local pilesNew = {}
  for key, val in pairs(saved) do
    if val.type then
      pilesNew[key] = restorePile(val)
    else
      pilesNew[key] = {}
      for i, pileInfo in ipairs(val) do
        pilesNew[key][i] = restorePile(pileInfo)
      end
    end
  end
  return pilesNew
end

function saveGameState()
  if not dragging.active then
    table.insert(history, { score=score, moves=moves, piles=serializePiles(piles) })
  end
end

function undoLastMove()
  if #history > 0 then
    local last = table.remove(history)
    score, moves = last.score, last.moves
    piles = restorePiles(last.piles)
    updateAllCardPositions()
  end
end

function love.load()
  math.randomseed(os.time())
  love.window.setTitle("Klondike Solitaire")
  love.window.setMode(960, 640)
  love.graphics.setBackgroundColor(0, 0.5, 0.2, 1)

  gameFont = love.graphics.newFont(14)
  love.graphics.setFont(gameFont)
  Buttons.load()
  cards, cardBack = CardAssets.loadCardImages()
  grabber = GrabberClass:new()
  initializeGame()
  lastClickTime = 0
  lastClickCard = nil
end

function initializeGame()
  history = {}
  piles = { tableau = {}, foundation = {}, stock = nil, waste = nil }
  for i = 1, 7 do
    piles.tableau[i] = PileClass:new(100 + (i-1)*(CARD_WIDTH+20), 150, "tableau", i)
  end
  for i = 1, 4 do
    piles.foundation[i] = PileClass:new(480 + (i-1)*(CARD_WIDTH+20), 50, "foundation", i)
  end
  piles.stock = PileClass:new(100, 50, "stock", 0)
  piles.waste = PileClass:new(200, 50, "waste", 0)
  deck = DeckClass:new()
  deck:shuffle()
  for i = 1, 7 do
    for j = 1, i do
      local card = deck:dealCard()
      if j == i then card:flip() end
      piles.tableau[i]:addCard(card)
    end
  end
  while true do
    local card = deck:dealCard() if not card then break end
    piles.stock:addCard(card)
  end
  updateAllCardPositions()
  dragging = { active=false, cards={}, sourcePile=nil, offsetX=0, offsetY=0 }
  gameWon = false
  score = 0
  moves = 0
end

function startDragging(cardsToDrag, sourcePile, x, y)
  startDragging(cardsToDrag, sourcePile, x, y)
end

function updateAllCardPositions()
  for _, pileType in pairs(piles) do
    if type(pileType)=="table" then
      if pileType.type then pileType:updateCardPositions()
      else for _, p in ipairs(pileType) do p:updateCardPositions() end end
    end
  end
end

function love.update(dt)
  grabber:update()
  if not gameWon then updateGame(dt) end
end

function updateGame(dt)
  checkForMouseMoving()
  for _, pileType in pairs(piles) do
    if type(pileType)=="table" then
      if pileType.type then pileType:update(dt)
      else for _, p in ipairs(pileType) do p:update(dt) end end
    end
  end
  if dragging.active then
    local mx,my = grabber.currentMousePos.x, grabber.currentMousePos.y
    for i,c in ipairs(dragging.cards) do
      c.x = mx - dragging.offsetX
      c.y = my - dragging.offsetY + (i-1)*CARD_OVERLAP
    end
  end
  checkForWin()
end

function love.draw()
  for _, f in ipairs(piles.foundation) do f:drawOutline() end
  for _, t in ipairs(piles.tableau)    do t:drawOutline() end
  piles.stock:drawOutline()
  piles.waste:drawOutline()
  for _, f in ipairs(piles.foundation) do f:draw() end
  for _, t in ipairs(piles.tableau)    do t:draw() end
  piles.stock:draw()
  piles.waste:draw()
  if dragging.active then for _, c in ipairs(dragging.cards) do c:draw() end end
  love.graphics.setColor(1,1,1,1)
  love.graphics.print("Score: "..score,10,10)
  love.graphics.print("Moves: "..moves,10,30)
  if gameWon then
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight())
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("You Win! Final Score: "..score,0,love.graphics.getHeight()/2-20,love.graphics.getWidth(),"center")
    love.graphics.printf("Press 'R' to play again",0,love.graphics.getHeight()/2+20,love.graphics.getWidth(),"center")
  end
  Buttons.draw()
end

function checkForMouseMoving()
  if not grabber.currentMousePos then return end
  for _, pileType in pairs(piles) do
    if type(pileType)=="table" then
      if pileType.type then pileType:checkForMouseOver(grabber)
      else for _, p in ipairs(pileType) do p:checkForMouseOver(grabber) end end
    end
  end
end

function handleCardClick(x,y,currentTime)
  local cardsToDrag, sourcePile = getCardsAt(x,y)
  if cardsToDrag and #cardsToDrag>0 then
    local isDoubleClick=false
    if lastClickCard==cardsToDrag[1] and currentTime-lastClickTime<DOUBLE_CLICK_TIME then
      isDoubleClick=tryAutoMoveToFoundation(cardsToDrag[1],sourcePile)
      if isDoubleClick then lastClickCard,lastClickTime=nil,0 return end
    end
    if cardsToDrag[1].faceUp then
      saveGameState()
      dragging.active=true
      dragging.cards=cardsToDrag
      dragging.sourcePile=sourcePile
      dragging.offsetX=x-cardsToDrag[1].x
      dragging.offsetY=y-cardsToDrag[1].y
      if #cardsToDrag==1 then sourcePile:removeCard(cardsToDrag[1])
      else sourcePile:removeCards(#sourcePile.cards-#cardsToDrag+1) end
    end
  end
  if cardsToDrag and #cardsToDrag>0 then lastClickCard=cardsToDrag[1]; lastClickTime=currentTime
  else lastClickCard=nil end
end

function handleStockClick()
  saveGameState()
  if #piles.stock.cards>0 then drawCardsFromStock() else resetStock() end
  moves = moves + 1
end

function love.mousepressed(x,y,button)
  local clicked = Buttons.mousepressed(x,y)
  if clicked=="reset" then initializeGame() return
  elseif clicked=="undo" then undoLastMove() return end
  if button==1 and not gameWon then
    local t=love.timer.getTime()
    if piles.stock:isPointInside(x,y) then handleStockClick() return end
    if not dragging.active then handleCardClick(x,y,t) end
  end
end

function love.mousereleased(x,y,button)
  if button==1 and dragging.active then
    local tp=getPileAt(x,y)
    local validMove=false
    if tp then validMove=isValidMove(dragging.cards,tp)
      if validMove then
        for _,c in ipairs(dragging.cards) do tp:addCard(c) end
        if dragging.sourcePile.type=="tableau" and #dragging.sourcePile.cards>0
          and not dragging.sourcePile.cards[#dragging.sourcePile.cards].faceUp then
          dragging.sourcePile.cards[#dragging.sourcePile.cards]:flip()
          score=score+5
        end
        updateScoreForMove(dragging.sourcePile,tp)
        moves=moves+1
      else for _,c in ipairs(dragging.cards) do dragging.sourcePile:addCard(c) end end
    else for _,c in ipairs(dragging.cards) do dragging.sourcePile:addCard(c) end end
    dragging.active=false; dragging.cards={}; dragging.sourcePile=nil
    updateAllCardPositions()
  end
end

function love.keypressed(key)
  if key=="r" or key=="n" then initializeGame() end
end

function drawCardsFromStock()
  if #piles.stock.cards==0 then return end
  local n=math.min(3,#piles.stock.cards)
  for i=1,n do local c=table.remove(piles.stock.cards); c:flip(); piles.waste:addCard(c) end
  updateAllCardPositions()
end

function resetStock()
  if #piles.stock.cards==0 and #piles.waste.cards>0 then
    while #piles.waste.cards>0 do
      local c=table.remove(piles.waste.cards) c:flip() piles.stock:addCard(c)
    end
    updateAllCardPositions()
    score = math.max(0, score - 100)
  end
end

function getCardsAt(x,y)
  if #piles.waste.cards>0 then
    local top = piles.waste.cards[#piles.waste.cards]
    if top:isPointInside(x,y) then return {top}, piles.waste end
  end
  for _,f in ipairs(piles.foundation) do
    if #f.cards>0 and f.cards[#f.cards]:isPointInside(x,y) then
      return {f.cards[#f.cards]}, f
    end
  end
  for _,t in ipairs(piles.tableau) do
    local found
    for i=#t.cards,1,-1 do
      local c = t.cards[i]
      if c.faceUp then
        local h = (i==#t.cards) and CARD_HEIGHT or CARD_OVERLAP
        if x>=c.x and x<=c.x+CARD_WIDTH and y>=c.y and y<=c.y+h then
          found=i; break
        end
      end
    end
    if found then
      local stack={}
      for j=found,#t.cards do table.insert(stack,t.cards[j]) end
      return stack, t
    end
  end
  return nil,nil
end

function getPileAt(x,y)
  for _,f in ipairs(piles.foundation) do if f:isPointInside(x,y) then return f end end
  for _,t in ipairs(piles.tableau) do
    if x>=t.x and x<=t.x+CARD_WIDTH and y>=t.y and y<=t.y+400 then return t end
  end
  if piles.waste:isPointInside(x,y) then return piles.waste end
  return nil
end

function isValidMove(cards,tp)
  if tp.type=="foundation" then
    if #cards>1 then return false end
    local c=cards[1]
    if #tp.cards==0 then return c.value==1
    else local top=tp.cards[#tp.cards] return c.suit==top.suit and c.value==top.value+1 end
  elseif tp.type=="tableau" then
    local bottom=cards[1]
    if #tp.cards==0 then return bottom.value==13
    else local top=tp.cards[#tp.cards]
      local opp=((bottom:isRed())~= (top:isRed()))
      return opp and bottom.value==top.value-1
    end
  end
  return false
end

function tryAutoMoveToFoundation(card,src)
  if not card or not card.faceUp then return false end
  for _,f in ipairs(piles.foundation) do
    if isValidMove({card},f) then
      if src.type=="waste" then saveGameState(); src:removeCard(card)
      else src:removeCard(card)
        if src.type=="tableau" and #src.cards>0 and not src.cards[#src.cards].faceUp then
          src.cards[#src.cards]:flip(); score=score+5
        end
      end
      f:addCard(card); updateScoreForMove(src,f); moves=moves+1; updateAllCardPositions()
      return true
    end
  end
  return false
end

function updateScoreForMove(src,tp)
  if tp.type=="foundation" then score=score+10
  elseif tp.type=="tableau" then
    if src.type=="waste" then score=score+5
    elseif src.type=="foundation" then score=score-15 end
  end
end

function checkForWin()
  local done=true
  for _,f in ipairs(piles.foundation) do if #f.cards<13 then done=false; break end end
  if done then gameWon=true; score=score+700 end
end
