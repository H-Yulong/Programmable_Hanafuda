local effects = {}

effects.gray = love.graphics.newShader([[
	vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords){
    	vec4 pixel = Texel(tex, texture_coords);
    	return pixel*0.85;
	} 
	]])


return effects