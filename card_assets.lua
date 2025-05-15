-- card_assets.lua

local CardAssets = {}

function CardAssets.loadCardImages()
  local cardBack = love.graphics.newImage("assets/card_back.png")

  local cards = {}
  local suits = { "clubs", "diamonds", "hearts", "spades" }
  local values = {
    [1] = "A", [2] = "02", [3] = "03", [4] = "04", [5] = "05",
    [6] = "06", [7] = "07", [8] = "08", [9] = "09", [10] = "10",
    [11] = "J", [12] = "Q", [13] = "K"
  }

  for _, suit in ipairs(suits) do
    cards[suit] = {}
    for value = 1, 13 do
      local filename = string.format("assets/card_%s_%s.png", suit, values[value])
      cards[suit][value] = love.graphics.newImage(filename)
    end
  end

  return cards, cardBack
end

return CardAssets
