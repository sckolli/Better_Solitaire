-- buttons.lua

local Buttons = {}

function Buttons.load()
  Buttons.list = {
    reset = { x = 800, y = 10, w = 70, h = 30, label = "Reset" },
    undo = { x = 720, y = 10, w = 70, h = 30, label = "Undo" }
  }
end

function Buttons.draw()
  for _, button in pairs(Buttons.list) do
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", button.x, button.y, button.w, button.h, 6, 6)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(button.label, button.x, button.y + 8, button.w, "center")
  end
end

function Buttons.mousepressed(x, y)
  for name, button in pairs(Buttons.list) do
    if x >= button.x and x <= button.x + button.w and y >= button.y and y <= button.y + button.h then
      return name
    end
  end
  return nil
end

return Buttons
