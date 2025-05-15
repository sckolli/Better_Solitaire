-- pile.lua
-- Pile class implementation for Klondike Solitaire

PileClass = {}
PileClass.__index = PileClass

function PileClass:new(x, y, pileType, index)
  local self = setmetatable({}, PileClass)
  
  self.x = x
  self.y = y
  self.type = pileType  
  self.index = index    
  self.cards = {}
  self.isHovered = false
  
  return self
end

function PileClass:update(dt)
  
  for _, card in ipairs(self.cards) do
    card:update(dt)
  end
end

function PileClass:draw()
  
  for i, card in ipairs(self.cards) do
    card:draw()
  end
  
  
  love.graphics.setColor(1, 1, 1, 1)
end

function PileClass:drawOutline()
 
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("line", self.x, self.y, CARD_WIDTH, CARD_HEIGHT, 5, 5)
  
  
  if self.type == "foundation" then
   
    love.graphics.setColor(1, 1, 1, 0.1)
    love.graphics.rectangle("fill", self.x, self.y, CARD_WIDTH, CARD_HEIGHT, 5, 5)
  end
  
  love.graphics.setColor(1, 1, 1, 1)
end

function PileClass:addCard(card)
  table.insert(self.cards, card)
  self:updateCardPositions()
  return self
end

function PileClass:removeCard(card)
  for i, c in ipairs(self.cards) do
    if c == card then
      table.remove(self.cards, i)
      break
    end
  end
  self:updateCardPositions()
end

function PileClass:removeCards(startIndex)
  local removed = {}
  
  while #self.cards >= startIndex do
    table.insert(removed, table.remove(self.cards))
  end
  
 
  local result = {}
  for i = #removed, 1, -1 do
    table.insert(result, removed[i])
  end
  
  self:updateCardPositions()
  return result
end

function PileClass:updateCardPositions()
 
  for i, card in ipairs(self.cards) do
    if self.type == "tableau" then
    
      card:moveTo(self.x, self.y + (i-1) * CARD_OVERLAP)
    elseif self.type == "waste" then
      
      local offset = 0
      if #self.cards > 1 then
        if i <= #self.cards - 3 then
         
          offset = 0
        else
          
          offset = (#self.cards - i) * 20
        end
      end
      card:moveTo(self.x - offset, self.y)
    else
      
      card:moveTo(self.x, self.y)
    end
  end
end

function PileClass:isPointInside(x, y)
  -- For tableau piles, create a taller hitbox
  local height = CARD_HEIGHT
  if self.type == "tableau" then
    height = math.max(CARD_HEIGHT, CARD_OVERLAP * #self.cards)
  end
  
  return x >= self.x and x <= self.x + CARD_WIDTH and
         y >= self.y and y <= self.y + height
end

function PileClass:checkForMouseOver(grabber)
  if grabber.currentMousePos == nil then
    self.isHovered = false
    return
  end
  
  local mouseX = grabber.currentMousePos.x
  local mouseY = grabber.currentMousePos.y
  
  self.isHovered = self:isPointInside(mouseX, mouseY)
  
  -- Check individual cards in the pile
  for _, card in ipairs(self.cards) do
    card:checkForMouseOver(grabber)
  end
end