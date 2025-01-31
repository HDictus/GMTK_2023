scenes = require("scenes")
font = love.graphics.newFont(18)
end_font = love.graphics.newFont(30)
function love.load()
   music = HAPPY
   mood = 'happy'
   music:play()
   music:setLooping(true)	
   mybutton = {x=(WIN_WIDTH - BUTTON_WIDTH)/2, y=WIN_HEIGHT-50, width=BUTTON_WIDTH, height=BUTTON_HEIGHT, text = love.graphics.newText(font, "Begin")}
   current_scene = {
      draw = function()
	 love.graphics.print(introduction)
	 draw_button(mybutton)
      end,
      mousepressed = function(self, x, y, button)
	 if button == 1 then --Left click
            if is_button_pressed(mybutton, x, y) then
	       scene_switch(cafe_intro)
	    end	
	 end
      end
   }
end

function love.keypressed(key)
   if current_scene.keypressed then
      current_scene:keypressed(key)
   end
end

function love.update(dt)
end

function love.draw()
current_scene:draw()
end

function draw_button(button)
love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
button_center_x = (button.x + button.width/2)
button_center_y = (button.y + button.height/2)
text_x = button_center_x - (button.text:getWidth()/2)
text_y = button_center_y - (button.text:getHeight()/2)
love.graphics.draw(button.text, text_x, text_y)
end

function scene_switch(new_scene)
   current_scene = new_scene
   if current_scene.mood then
      set_mood(current_scene.mood)
   end
end



function is_button_pressed(button, x, y)
	if x >= button.x and x <= button.x+button.width and y >= button.y and y <= button.y+button.height then --Detect if the click was inside the button
		return true --This is what triggers the pop-up image
    end
end		
		

function love.mousepressed(x, y, button ,istouch)
    current_scene:mousepressed(x, y, button)
end

HAPPY = love.audio.newSource("music/Happy.wav", "stream")
ROMANTIC = love.audio.newSource("music/Romantic.wav", "stream")
TENSE = love.audio.newSource("music/Sinister.wav", "stream")


introduction = {"This is a story of two people meeting, and how their relationship develops. You control the music driving their story."}


BUTTON_WIDTH = 80
BUTTON_HEIGHT = 40
WIN_WIDTH, WIN_HEIGHT = love.window.getMode()
Scene = {
    romantic_button = {x=20, y=WIN_HEIGHT-50, width=BUTTON_WIDTH, height=BUTTON_HEIGHT, text=love.graphics.newText(font, "Track 1")},
	happy_button = {x=(WIN_WIDTH - BUTTON_WIDTH)/2, y=WIN_HEIGHT-50, width=BUTTON_WIDTH, height=BUTTON_HEIGHT, text=love.graphics.newText(font, "Track 2")},
	tense_button = {x=WIN_WIDTH - 20 - BUTTON_WIDTH, y=WIN_HEIGHT-50, width=BUTTON_WIDTH, height=BUTTON_HEIGHT, text=love.graphics.newText(font, "Track 3")}
}

function Scene.new(lines)
   local o = {}
   o.lines = lines
   setmetatable(o, {__index=Scene})
   o.line_number = 1
   o.mood = o.lines.mood
   return o
end


music_moods = {
   romantic=ROMANTIC,
   happy=HAPPY,
   tense=TENSE}
function set_mood(value)
   mood = value
   music:pause()
   music = music_moods[value]
   music:play()
end


function Scene:mousepressed(x, y, button)
   if self.mood then
      -- mood is locked
      return
   end
   if is_button_pressed(self.romantic_button, x, y) then
      set_mood("romantic")
   elseif is_button_pressed(self.happy_button, x, y) then
      set_mood('happy')
   elseif is_button_pressed(self.tense_button, x, y) then
      set_mood('tense')
   end	
end

function Scene:get_next_scene()
   local next_lines
   if self.lines[mood] == nil then
      next_lines = scenes[self.lines.next]
      if next_lines == nil then
		if self.lines.next == nil then
			return end_screen
		end
	  error("undefined scene: "..self.lines.next)
      end
   else 
	if self.isfirstdate and mood == "tense" then
		first_date_went_poorly = true
	end
	next_lines = self.lines[mood]
	next_lines.mood = mood
   end
   
   return Scene.new(resolve_conditions(next_lines))
end

function find_last(str, expr)
   local ind = 1
   local found = true
   while ind < string.len(str) and found do
	   found = string.find(str, expr, ind+1)
	   if found then ind = found end
   end
   return ind
end

function Scene:draw()
   if not self.mood then
      draw_button(self.romantic_button)
      draw_button(self.happy_button)
      draw_button(self.tense_button)
   end
   yoffset= 0
   for i , line in ipairs(self.lines) do
      if i > self.line_number then	
	     break
      end		
	if string.len(line) > 80 then
	    local split_position = find_last(
		    string.sub(line, 1, 80), " ")
		line = string.sub(line, 1, split_position) .."\n" .. string.sub(line, split_position + 1)
	end	  
      line_text = love.graphics.newText(font, line)
      love.graphics.draw(line_text, 0, yoffset)
      yoffset = yoffset + line_text:getHeight()
		
   end
end

function resolve_conditions(lines)
	local output_table = {}
	for i, line in ipairs(lines) do
		if type(line) == "string" then 
			table.insert(output_table, line)
		else
			for j, function_line in ipairs(line()) do 
				table.insert(output_table, function_line)
			end
		end
	end
	for key, value in pairs(lines) do
		if type(key) == "string" then 
			output_table[key] = value
		end	
	end
	return output_table
end


function Scene:keypressed(key)
   if key == 'escape' then
      love.quit()
   end
   self.line_number = self.line_number + 1
   if self.line_number > #self.lines then 
      scene_switch(self:get_next_scene())
   end
end

cafe_intro = Scene.new(scenes.CAFE)
cafe_intro.isfirstdate = true


end_screen = {
   draw = function()
      local line_text = love.graphics.newText(end_font, "THE END\n\n\nThank you for playing\n\nPress escape to exit.\nPress R to restart")
      love.graphics.draw(
	 line_text,
	 WIN_WIDTH/2 - line_text:getWidth()/2,
	 WIN_HEIGHT/2 - line_text:getHeight()/2)
   end,
   keypressed = function(self, key)
      if key == 'escape' then
	 love.event.quit()
      elseif key == 'r' then
	 love.event.quit("restart")
      end
   end
}

