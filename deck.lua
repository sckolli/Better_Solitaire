-- deck.lua
-- Deck class implementation for Klondike Solitaire

DeckClass = {}
DeckClass.__index = DeckClass

function DeckClass:new()
  local self = setmetatable({}, DeckClass)
  
  self.cards = {}
  
  
  
  local suits = {"hearts", "diamonds", "clubs", "spades"}
  
  for _, suit in ipairs(suits) do
    for value = 1, 13 do
      table.insert(self.cards, CardClass:new(suit, value))
    end
  end
  
  return self
end

function DeckClass:shuffle()
  
  for i = #self.cards, 2, -1 do
    local j = math.random(i)
    self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
  end
  
  return self
end

function DeckClass:dealCard()
  if #self.cards > 0 then
    return table.remove(self.cards)
  else
    return nil
  end
end