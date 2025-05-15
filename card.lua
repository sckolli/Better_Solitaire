-- card.lua
-- Card class implementation for Klondike Solitaire

CardClass = {}
CardClass.__index = CardClass

function CardClass:new(suit, value, x, y)
  local self = setmetatable({}, CardClass)
  
  
  self.x = x or 0
  self.y = y or 0
  self.suit = suit or "hearts" 
  self.value = value or 1      
  self.faceUp = false
  self.isHovered = false
  
 
  self.targetX = self.x
  self.targetY = self.y
  
  return self
end

function CardClass:getValueName()
  if self.value == 1 then
    return "ace"
  elseif self.value == 11 then
    return "jack"
  elseif self.value == 12 then
    return "queen"
  elseif self.value == 13 then
    return "king"
  else
    return tostring(self.value)
  end
end

function CardClass:update(dt)
  
  if math.abs(self.x - self.targetX) > 0.5 or math.abs(self.y - self.targetY) > 0.5 then
    self.x = self.x + (self.targetX - self.x) * ANIMATION_SPEED
    self.y = self.y + (self.targetY - self.y) * ANIMATION_SPEED
  else
    self.x = self.targetX
    self.y = self.targetY
  end
end

function CardClass:draw()
  if self.faceUp then
   
    love.graphics.setColor(1, 1, 1, 1)
    local cardImage = cards[self.suit][self.value]
    love.graphics.draw(cardImage, self.x, self.y)
  else
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(cardBack, self.x, self.y)
  end
  
 
  if self.isHovered then
    love.graphics.setColor(1, 1, 0, 0.3)
    love.graphics.rectangle("fill", self.x, self.y, CARD_WIDTH, CARD_HEIGHT, 5, 5)
  end
  
  
  love.graphics.setColor(1, 1, 1, 1)
end

function CardClass:moveTo(x, y, immediate)
  if immediate then
    self.x = x
    self.y = y
    self.targetX = x
    self.targetY = y
  else
    self.targetX = x
    self.targetY = y
  end
end

function CardClass:flip()
  self.faceUp = not self.faceUp
  return self
end

function CardClass:isPointInside(x, y)
  return x >= self.x and x <= self.x + CARD_WIDTH and
         y >= self.y and y <= self.y + CARD_HEIGHT
end

function CardClass:checkForMouseOver(grabber)
  if grabber.currentMousePos == nil then
    self.isHovered = false
    return
  end
  
  local mouseX = grabber.currentMousePos.x
  local mouseY = grabber.currentMousePos.y
  
  self.isHovered = self:isPointInside(mouseX, mouseY)
end

function CardClass:isRed()
  return self.suit == "hearts" or self.suit == "diamonds"
end