gamestate = require "lib.hump.gamestate"
Timer = require "lib.hump.timer"
Slab = require "lib.slab"
require "lib.Tserial"
require "lib.loveframes"
Class = require "lib.hump.class"
utf8 = require("utf8")

local speed_up = false


states = {
	battle = require "game.states.Battle",
	credit = require "game.states.Credit",
	envedit = require "game.states.EnvEdit",
	loading = require "game.states.Loading",
	menu = require "game.states.Menu",
	prebattle = require "game.states.PreBattle",
	tutorial = require "game.states.Tutorial",
	afterbattle = require "game.states.AfterBattle",
	customrules = require "game.states.CustomRules"

}

function love.load()  
	gamestate.registerEvents({'update'})
	gamestate.switch(states.menu)
	Slab.Initialize()
end

function love.update(dt)
	if speed_up then
		dt = dt * 5
	end
  Timer.update(dt)
  gamestate.update(dt)
  Slab.Update(dt)
end

function love.draw()
  gamestate.draw()
  Slab.Draw()
end

function love.mousereleased(...)
    gamestate.mousereleased(...)
end

function love.mousepressed(...)
    gamestate.mousepressed(...)
end

function love.wheelmoved(...)
	gamestate.wheelmoved(...)
end

function love.keypressed(...)
    if key == "lctrl" then
    	speed_up = true
    end
    gamestate.keypressed(...)
end

function love.keyreleased(key)
    if key == "lctrl" then
    	speed_up = false
    end
end

-- Limit the frame rate to 300fps 
FRAME_ACCUM = 0
function love.run()
 
	if love.math then
		love.math.setRandomSeed(os.time())
	end
 
	if love.load then love.load(arg) end
 
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end
 
	local dt = 0
 
	-- Main loop time.
	while true do
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end
 
		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end

		FRAME_ACCUM = FRAME_ACCUM + dt
 
 		if FRAME_ACCUM > 1/300 then
			-- Call update and draw
			if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
    
			if love.graphics and love.graphics.isActive() then
				love.graphics.clear(love.graphics.getBackgroundColor())
				love.graphics.origin()
				if love.draw then love.draw() end
				love.graphics.present()
			end

			FRAME_ACCUM = math.min(1/300, FRAME_ACCUM - 1/300)
		end
 
		if love.timer then love.timer.sleep(0.001) end
	end
 
end

function love.quit()
  gamestate.quit()
end
	