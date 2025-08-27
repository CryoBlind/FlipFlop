pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--flip flop
--by carter dean
--vvvvvv inspired infinite runner for the make games cabinet at the lassonde makerspace at the university of utah
--contact at: cwdean8@gmail.com
--
--framework for game object creation provided by mason hirschi
--maceface999@gmail.com
--"meivengine"

function _init()
    scene = 0
    first_run = true
    show_leaderboard = false
    player = nil
    player_head_set_index = 64
    player_body_set_index = player_head_set_index + 16 --row below head
    player_body_part_selection = 0
    player_frame_loop = {0, 1, 2, 1}
    preview_frame_index = 1
    preview_frame_counter = 0
    preview_head_bob_offset = 0
    score = 0
    last_tile_ended_top = false
    camera_offset = 0
    precise_camera_offset = 0
    objs = {}
    gravity_accel = 0.5
    highscore = highscore or 0
    jump_btn = 5
    grav_btn = 4
    layer_1_map_scroll = 0
    layer_2_map_scroll = 0
    layer_3_map_scroll = 0
    cam = {x = 0, y = 0, speed = 0}
    game_is_running = false
    update_frame = true
    stopped_game_map_coords = {x = 112, y = 48}
    first_animation_set_start = 64
    last_animation_set_start = 108


    leaderboard_size = 10
    leaderboard_scroll_index = 0
    leaderboard = {}
    for i = 1, leaderboard_size do
        leaderboard[i] = {}
        for j = 1, 3 do
            leaderboard[i][j] = 0
        end
    end

    cartdata("cryo_flipflop_leaderboard_v1_1") --load leaderboard from cartdata

    for i = 1, leaderboard_size do -- load leaderboard
        leaderboard[i][1] = dget((i-1)*3)
        leaderboard[i][2] = dget((i-1)*3 + 1)
        leaderboard[i][3] = dget((i-1)*3 + 2)
    end

    
end

function game_loop()
    if update_frame then
        for o in all(objs) do
            if o.update and update_frame then
                o:update()
            end
            if o.dead then
                del(objs, o)
            end
        end
    end
    update_frame = not update_frame
    player:update()
end

function menu_loop()
    if btnp(❎) then
        start_game()
        sfx(5, 2)
    end
    if btnp(🅾️) then
        show_leaderboard = not show_leaderboard
        sfx(4, 0)
    end

    if not show_leaderboard then
        if btnp(⬆️) then
            player_body_part_selection = clamp(player_body_part_selection - 1, 0, 1)
            sfx(4, 0)
        end
        if btnp(⬇️) then
            player_body_part_selection = clamp(player_body_part_selection + 1, 0, 1)
            sfx(4, 0)
        end
        if btnp(➡️) then
            if player_body_part_selection == 0 then
                player_head_set_index += 3
                if player_head_set_index % 16 == 15 then player_head_set_index += (1 + 16) end
                if player_head_set_index > last_animation_set_start then player_head_set_index = first_animation_set_start end --loop to the start of head sets
            else
                player_body_set_index += 3
                if player_body_set_index % 16 == 15 then player_body_set_index += (1 + 16) end
                if player_body_set_index > last_animation_set_start + 16 then player_body_set_index = first_animation_set_start + 16 end --loop to the start of body sets
            end
            sfx(4, 0)
        end
        if btnp(⬅️) then
            if player_body_part_selection == 0 then
                player_head_set_index -= 3
                if (player_head_set_index % 16) % 3 != 0 then player_head_set_index -= (1 + 16) end
                if player_head_set_index < first_animation_set_start then player_head_set_index = last_animation_set_start end --loop to the end of head sets
            else
                player_body_set_index -= 3
                if (player_body_set_index % 16) % 3 != 0 then player_body_set_index -= (1 + 16) end
                if player_body_set_index < first_animation_set_start + 16 then player_body_set_index = last_animation_set_start + 16 end --loop to the end of body sets
            end
            sfx(4, 0)
        end
    end
end


function _update60()
    if scene == 1 then
        game_loop()
    else
        menu_loop()
    end

    draw()
end

function draw_game()
    local animation_frame_delay = 6
    --update preview frame
    preview_frame_counter += 1
    if preview_frame_counter > animation_frame_delay then
        preview_frame_counter = 0
        preview_frame_index += 1
        if preview_frame_index > #player_frame_loop then
            preview_frame_index = 1
        end
    end

    --draw background
    draw_sun(10 + cam.x, 30, 1)   
    
    --draw clouds
    draw_cloud(cam.x - flr(layer_3_map_scroll), cam.y, 2)
    draw_cloud(cam.x + 128 - flr(layer_3_map_scroll), cam.y, 2)

    draw_cloud(cam.x - flr(layer_2_map_scroll) + 90, cam.y + 30, 1)
    draw_cloud(cam.x + 128 - flr(layer_2_map_scroll) + 90, cam.y + 30, 1)

    draw_cloud(cam.x - flr(layer_2_map_scroll) + 35, cam.y + 50, 1.5)
    draw_cloud(cam.x + 128 - flr(layer_2_map_scroll) + 35, cam.y + 50, 1.5)

    --draw birds
    draw_bird(cam.x - flr(layer_1_map_scroll) + 90, 36, 1.5, false)
    draw_bird(cam.x + 128 - flr(layer_1_map_scroll) + 90, 36, 1.5, false)

    --draw trees
    draw_tree(cam.x + 256 - flr(layer_1_map_scroll) - 10, 48, 2, false)
    draw_tree(cam.x + 128 - flr(layer_1_map_scroll) - 10, 48, 2, false)
    draw_tree(cam.x - flr(layer_1_map_scroll) - 10, 48, 2, false)
    
    

    map(0,0,0,0,128,16)

    for o in all(objs) do
        if o.draw then
            o:draw()
        end
    end

    print("score: "..flr(score), cam.x + 2, cam.y + 2, 7)
    if not first_run then print("session highscore: "..flr(highscore), cam.x + 2, cam.y + 9, 7) end
end

function draw_menu()
    --draw sun
    draw_sun(10, 30, 1)

    --draw tree
    draw_tree(-8, 48, 2, false)

    --draw clouds
    draw_cloud(-1*8, 4*8, 1)
    draw_cloud(8*8, 3*8, 1)
    draw_cloud(12*8, 6*8, 1)

    --draw top line of grass
    for i = 0, 15 do spr(16, i*8, 0) end
    for i = 0, 15 do spr(1, i*8, 8) end

    --draw bottom line of grass
    for i = 0, 15 do spr(16, i*8, 120) end
    for i = 0, 15 do spr(17, i*8, 112) end

    --draw pipe
    spr(2, 2*8, 1*8, 2, 1)
    spr(18, 2*8, 2*8, 2, 1)
    spr(18, 2*8, 3*8, 2, 1)
    spr(18, 2*8, 4*8, 2, 1)
    spr(18, 2*8, 5*8, 2, 1)
    spr(34, 2*8, 6*8, 2, 1)

    --draw bricks
    spr(38, 11*8, 11*8, 3, 2)

    --draw logo
    draw_logo(14, 17, 2)
    --draw player customizer
    draw_player_customizer(17, 69, 2)

    print("press 🅾️ for leaderboard!", cam.x + 15, cam.y + 3, 7)

    if show_leaderboard then
        draw_leaderboard()
    end
end

function draw()
    cls(12)
    camera(cam.x,cam.y)

    if scene == 1 then -- game screen
        draw_game()
    elseif scene == 2 then -- game over screen
        draw_menu()
        print("press ❎ to restart!", cam.x + 28, cam.y + 120, 7)
        if not show_leaderboard then
            print("score: "..flr(score), cam.x + 3, cam.y + 106, 7)
        else
            print("session highscore: "..flr(highscore), cam.x + 17 , cam.y + 108, 7)
        end
        
    else -- start screen
        draw_menu()
        print("press ❎ to start!", cam.x + 30, cam.y + 120, 7)
    end

    if player then player:draw() end -- draw player
end

function start_game()
    scene = 1
    player = new_player(64, 56)
    score = 0
    camera_offset = player.x
    precise_camera_offset = player.x
    cam.x = player.x - camera_offset
    cam.y = 0
    cam.speed = 0
    game_is_running = true
    stopped_game_map_coords.x = 96
    stopped_game_map_coords.y = 48
    objs = {}
    show_leaderboard = false

    --create first 2 sections of map as empty
    last_tile_ended_top = false
    for i = 0, 1 do
        --draw top line of grass
        for j = 0, 15 do mset(i*16+j, 0, 16) end
        for j = 0, 15 do mset(i*16+j, 1, 1) end

        --empty middle
        for j = 2, 13 do 
            for k = 0, 15 do
                mset(i*16+k, j, 0)
            end
        end

        --draw bottom line of grass
        for j = 0, 15 do mset(i*16+j, 15, 16) end
        for j = 0, 15 do mset(i*16+j, 14, 17) end
    end
    
    replace_map_strip(2, 7)

    return true
end

function end_game()
    if score > highscore then
        highscore = score
    end
    update_leaderboard(score)
    scene = 2
    cam.x = 0
    cam.y = 0
    game_is_running = false
    player = nil
    first_run = false
    return false
end

-->8
--game objects
function new_game_object(x, y, w, h, update, draw, vars)
    local obj = {x = x, y = y, w = w, h = h, update = update, draw = draw, dead = false,
        die = function(sf)
            if not sf.dead and sf.ondeath then
                sf:ondeath()
            end
            sf.dead = true
        end,
        transform = function(sf,dx,dy)
			sf.x += dx
			sf.y += dy
		end}

        if vars then
            add_object_vars(obj,vars)
        end

    return obj
end

function new_player(x, y)
    local play = new_game_object(x, y, 6, 12,
    function(sf) -- update
        handle_input(sf)
        if not sf.is_grounded and not sf.jumped then
            sf.y_velocity += gravity_accel * sf.falling_velocity_mult
        else
            sf.y_velocity += gravity_accel
        end
        cam.speed = sf.speed


        if hit(sf.x + sf.x_velocity, sf.y, sf.w, sf.h) then
            --horizontal collision snap
            sf.x_velocity -= 1
            if sf.x_velocity > 0 then
                while hit(sf.x + sf.x_velocity, sf.y, sf.w, sf.h) do
                    sf.x_velocity -= 1
                end
            end
        end
        
        if hit(sf.x, sf.y + sf.y_velocity * sf.gravity_dir, sf.w, sf.h) then
            --vertical collision snap
            local dir_to_move = 0
            local should_ground = false
            if sf.y_velocity < 0 then
                dir_to_move = 1
            else
                dir_to_move = -1
                should_ground = true
            end
            sf.y_velocity += dir_to_move

            while hit(sf.x, sf.y + sf.y_velocity * sf.gravity_dir, sf.w, sf.h) do
                sf.y_velocity += dir_to_move
            end
            if should_ground then -- only ground when velocity is positive (moving with gravity)
                 sf.is_grounded = true
                 sf.jumped = false
            end 
            sf.coyote_timer = 0
            
        else
            if sf.coyote_timer > 0 then
                sf.coyote_timer -= 1
            else
                sf.is_grounded = false
            end
        end

        sf.y += clamp(sf.y_velocity * sf.gravity_dir, -sf.max_velocity, sf.max_velocity)
        sf.x += sf.x_velocity
        sf.y = clamp(sf.y, 15, 112 - sf.h)

        sf.x_velocity = clamp(sf.x_velocity, 0, sf.max_velocity)

        if abs(sf.x_velocity) < sf.speed then
            precise_camera_offset -= sf.speed/4
            cam.speed = cam.speed/2
        else
            precise_camera_offset = clamp(precise_camera_offset + sf.speed/16, -20, 64)
        end

        layer_1_map_scroll += cam.speed/2
        layer_1_map_scroll = layer_1_map_scroll % 128
        layer_2_map_scroll += cam.speed/4
        layer_2_map_scroll = layer_2_map_scroll % 128
        layer_3_map_scroll += cam.speed/8
        layer_3_map_scroll = layer_3_map_scroll % 128
        
        camera_offset = flr(precise_camera_offset)

        cam.x = flr(sf.x - camera_offset)

        if sf.x > sf.farthest_x then
            score += (sf.x - sf.farthest_x)
            sf.farthest_x = sf.x
        end
        sf:wrap_around()
        --kill player if they fall behind the camera
        if camera_offset < -10 then
            sf:die()
        end
    end,
    function(sf) -- draw
        --rectfill(sf.x, sf.y, sf.x + sf.w, sf.y + sf.h, 15) -- draw hitbox

        --looping logic
        if sf.frame_counter > sf.frame_delay then
            sf.frame_counter = 0
            sf.frame_index = sf.frame_index + 1
            if sf.frame_index > 4 then
                sf.frame_index = 1
            end
        else
            if sf.is_grounded then
                sf.frame_counter += 1
            end
        end

        --head bobbing
        if player_frame_loop[sf.frame_index] == 1 then
            sf.head_bob_offset = 1
        else
            sf.head_bob_offset = 0
        end

        --draw player
        if sf.gravity_dir == 1 then --normal gravity
            spr(player_body_set_index + player_frame_loop[sf.frame_index], sf.x, sf.y + 5, 1, 1, false, false)
            spr(player_head_set_index + player_frame_loop[sf.frame_index], sf.x, sf.y + sf.head_bob_offset - 2, 1, 1, false, false)
        else --flipped gravity
            spr(player_body_set_index + player_frame_loop[sf.frame_index], sf.x, sf.y, 1, 1, false, true)
            spr(player_head_set_index + player_frame_loop[sf.frame_index], sf.x, sf.y - sf.head_bob_offset + 7, 1, 1, false, true)
        end

        --play footstep sound and create particle effect
        if sf.is_grounded and player_frame_loop[sf.frame_index] == 1 and sf.frame_counter == 1 then
            --new_particle_obj(clr,x,y,size,vx,vy,grow,span,draw)
            add(objs, new_particle_obj(5,sf.x + sf.w/2,sf.y + (sf.h + 1)*clamp(sf.gravity_dir, 0, 1),1,0,-0.2*sf.gravity_dir,0.2,7))
            sfx(0, 0)
        end
    end, 
    {y_velocity = 0,
    x_velocity = 0,
    x_acceleration = 0.2,
    starting_x_acceleration = 0.2,
    is_grounded = false,
    jumped = false,
    falling_velocity_mult = 2,
    starting_speed = 1.5,
    speed = 1.5,
    jump_strength = 7,
    coyote_timer = 4,
    early_jump = 0,
    early_grav = 0,
    gravity_dir = 1,
    x_dir = 1,
    max_velocity = 7,
    farthest_x = x,
    speed_mult = 0.07,
    frame_counter = 0,
    frame_index = 1,
    starting_frame_delay = 3,
    frame_delay = 3,
    head_bob_offset = 0,
    jump = function(sf)
        if sf.is_grounded then
            sf.is_grounded = false
            sf.jumped = true
            sf.frame_counter = sf.frame_delay
            sf.frame_index = 1
            sf.y_velocity = -sf.jump_strength
            sfx(1, 1)
        end
    end,
    swap_grav = function(sf)
        if not sf.jumped then
            sf.is_grounded = false
            sf.jumped = true
            sf.gravity_dir = -sf.gravity_dir
            sf.y_velocity = 4
            sfx(2, 1)
        end
    end,
    wrap_around = function(sf)
        if sf.x > 1024 - 128 + camera_offset then
            replace_map_strip(0, 7)
            camera_offset = clamp(camera_offset, 0, 128)
            precise_camera_offset = camera_offset
            sf.x = camera_offset
            cam.x = sf.x - camera_offset
            sf.farthest_x = sf.x
            sf.speed += sf.speed_mult*sf.starting_speed
            sf.frame_delay -= sf.starting_frame_delay*sf.speed_mult
            sf.x_acceleration += sf.starting_x_acceleration*(sf.speed_mult + 0.02)
        end
    end,
    ondeath = function(sf)
        --play death sound
        sfx(3, 0)
        end_game()
    end})

    return play
end

--[[
    from mason hirschi
	creates a basic particle
	object. has color, position,
	velocity, lifespan (in frames),
	growth rate, and start size.
	
	the particle will by default
	draw a circle but you can
	also optionally pass in a
	function to "draw" for
	custom appearance. the function
	should have a signature of:
	(x,y,size,color)
]]
function new_particle_obj(clr,x,y,isize,vx,vy,igrow,ispan,draw)
    local obj = {clr = clr, x = x, y = y, size = isize, vx = vx, vy = vy, grow = igrow, span = ispan,
    update = function(sf)
		sf.size+=sf.grow
		sf:transform(sf.vx,sf.vy)
		sf.span-=1
		if sf.span<0 then
			sf:die()
		end
	end, 
    draw = function(sf)
		if sf.altdraw then
			sf.altdraw(sf.x,sf.y,sf.size,sf.clr)
		else
			--circfill(sf.x,sf.y,sf.size,sf.clr)
			local x,y,s = sf.x,sf.y,sf.size/2
			ovalfill(x-s,y-s,x+s,y+s,sf.clr)
		end
	end, 
    dead = false,
        die = function(sf)
            if not sf.dead and sf.ondeath then
                sf:ondeath()
            end
            sf.dead = true
        end,
        transform = function(sf,dx,dy)
			sf.x += dx
			sf.y += dy
		end,
        --default z-value
        z=-1,
        --default lifespan
        altdraw=draw,
    }

    return obj
end

-->8
--util functions

--[[Function to replace the entire runner-strip with a new, randomly generated map using other sections of the map]]
function replace_map_strip(start_replace, end_replace)
    if start_replace == 0 then 
        copy_map_section(112, 0, 16, 16, 0, 0) -- set first section of map to the end of the old strip
        start_replace = start_replace + 1
    end

    for i = start_replace, end_replace do

        local rnd_section_start = 64
        if last_tile_ended_top then rnd_section_start = 0 end
        
        rnd_x = flr(rnd(4))*16 + rnd_section_start
        rnd_y = flr(rnd(3))*16 + 16
        
        copy_map_section(rnd_x, rnd_y, 16, 16, i*16, 0)

        last_tile_ended_top = rnd_x == 0 or rnd_x == 16 or rnd_x == 64 or rnd_x == 80
    end
end


--[[Function to select a 16x16 area of the map, 
taking a parameter for the x and y coordinates of the top left corner 
of the area and setting another section of map to the same tiles by looping accross the map
and copying the tiles from the selected area to the new area]]
function copy_map_section(x, y, w, h, new_x, new_y)
    for i = 0, w-1 do
        for j = 0, h-1 do
            mset(new_x + i, new_y + j, mget(x + i, y + j))
        end
    end
end



--[[button 0: left
    button 1: right
    button 2: up
    button 3: down
    button 4: O
    button 5: X]]
function handle_input(sf)
    sf.x_velocity = clamp(sf.x_velocity+sf.x_acceleration, 0, sf.speed)
    if btnp(grav_btn) then
        if sf.is_grounded then
            sf.early_grav = 0
            sf:swap_grav()
        else sf.early_grav = 6
        end
    end
    if btnp(jump_btn) then
        if sf.is_grounded then
            sf.early_jump = 0
            sf:jump()
        else sf.early_jump = 6
        end
    end

    if sf.early_jump > 0 then --logic for if the jump is pressed a frame or 2 before being grounded
        if sf.is_grounded then
            sf.early_jump = 0
            sf:jump()
        else 
            sf.early_jump -= 1
        end
    end
    if sf.early_grav > 0 then --logic for if the grav button is pressed a frame or 2 before being grounded
        if sf.is_grounded then
            sf.early_grav = 0
            sf:swap_grav()
        else 
            sf.early_grav -= 1
        end
    end
end

function add_object_vars(obj,vars)
    printh("adding vars to new to object")
	for k,v in pairs(vars) do
        printh("adding var "..k.." to object")
		obj[k] = v
	end
end

function hit(x,y,w,h)
    collide=false
    for i=x,x+w,w do
      if (fget(mget(i/8,y/8))>0) or
           (fget(mget(i/8,(y+h)/8))>0) then
            collide=true
      end
    end
    
    for i=y,y+h,h do
      if (fget(mget(x/8,i/8))>0) or
           (fget(mget((x+w)/8,i/8))>0) then
            collide=true
      end
    end
    
    return collide
  end

  function move_camera()
        if px-leftbufferplusfreezone>camx then
            camx=min(px-leftbufferplusfreezone,mapwidth-screenwidth)
        else 
            if px-leftbuffer<camx then
            camx=max(0,px-leftbuffer)
            end
        end
    end

function clamp(val,vmin,vmax)
	return min(max(val,vmin),vmax)
end

function draw_tree(x, y, scale, flip)
    sspr(72, 0, 24, 32, x, y, 24*scale, 32*scale, flip)
end 
function draw_bird(x, y, scale, flip)
    sspr(120, 40 + player_frame_loop[preview_frame_index]*8, 8, 8, x, y, 8*scale, 8*scale, flip)
end 
function draw_sun(x, y, scale)
    circfill(x, y, 8*scale, 9)
    line(x-8*scale, y-8*scale, x + 8*scale, y + 8*scale, 9)
    line(x+8*scale, y-8*scale, x - 8*scale, y + 8*scale, 9)
    circfill(x, y, 8*scale-1, 10)
    --sspr(72, 0, 16, 16, x, y, 16*scale, 16*scale)
end
function draw_cloud(x, y, scale)
    sspr(48, 0, 24, 16, x, y, 24*scale, 16*scale)
end
function draw_logo(x, y, scale)
    local letter_spacing = 1
    local curr_x = x
    local curr_y = y
    --flip
    sspr(96, 0, 8, 12, curr_x, y, 8*scale, 12*scale)
    curr_x += 8*scale + letter_spacing
    sspr(104, 0, 8, 12, curr_x, y, 8*scale, 12*scale)
    curr_x += 8*scale + letter_spacing
    sspr(112, 0, 8, 12, curr_x, y, 8*scale, 12*scale)
    curr_x += 8*scale + letter_spacing
    sspr(120, 0, 8, 12, curr_x, y, 8*scale, 12*scale)
    curr_x += 8*scale + letter_spacing

    curr_x = x + (curr_x - x)/2
    curr_y = y + 12*scale + 1
    
    --flop
    sspr(120, 0, 8, 12, curr_x, curr_y, 8*scale, 12*scale, true, true)
    curr_x += 8*scale + letter_spacing
    sspr(96, 12, 8, 12, curr_x, curr_y, 8*scale, 12*scale, true, true)
    curr_x += 8*scale + letter_spacing
    sspr(104, 0, 8, 12, curr_x, curr_y, 8*scale, 12*scale, true, true)
    curr_x += 8*scale + letter_spacing
    sspr(96, 0, 8, 12, curr_x, curr_y, 8*scale, 12*scale, true, true)
end

function draw_player_customizer(x, y, character_scale)
    local leftright_margin = flr(95 - 7*character_scale)/2
    local topbottom_margin = 14
    local animation_frame_delay = 20

    --update preview frame
    preview_frame_counter += 1
    if preview_frame_counter > animation_frame_delay then
        preview_frame_counter = 0
        preview_frame_index += 1
        if preview_frame_index > #player_frame_loop then
            preview_frame_index = 1
        end
    end

    --head bobbing
    if player_frame_loop[preview_frame_index] == 1 then
        preview_head_bob_offset = 1
    else
        preview_head_bob_offset = 0
    end
    
    --draw background
    rectfill(x-1, y-1, x + 95, y + 5, 0)
    --rectfill(x + leftright_margin - 9, y + topbottom_margin - 6, x + 8*character_scale + leftright_margin + 7, y + 16*character_scale + topbottom_margin + 1, 0)
    --draw text
    print("cUSTOMIZE YOUR CHARACTER", x, y, 7)

    --draw arrows
    print("➡️", x + leftright_margin + 8*character_scale, y + topbottom_margin + 3*character_scale + 4*character_scale*player_body_part_selection, 7)
    print("⬅️", x + leftright_margin - (8*character_scale)/2, y + topbottom_margin + 3*character_scale + 4*character_scale*player_body_part_selection, 7)

    print("⬇️", x + leftright_margin + 2*character_scale, y + topbottom_margin + 14*character_scale, 7)
    print("⬆️", x + leftright_margin + 2*character_scale, y + topbottom_margin - 5, 7)

    --draw player body
    sspr((player_body_set_index % 16) * 8 + 8 * player_frame_loop[preview_frame_index], flr(player_body_set_index / 16) * 8, 8, 8, x + leftright_margin, y + topbottom_margin + 5*character_scale, 8 * character_scale, 8 * character_scale, false, false)
    sspr((player_head_set_index % 16) * 8 + 8 * player_frame_loop[preview_frame_index], flr(player_head_set_index / 16) * 8, 8, 8, x + leftright_margin, y + topbottom_margin - 2*character_scale + flr(preview_head_bob_offset*character_scale), 8 * character_scale, 8 * character_scale, false, false)
end

function draw_leaderboard()
    local x = 30
    local y = 16
    local row_height = 17
    local col_width = 40
    local num_columns = 2
    local leaderboard_index = 1
    --top left corner
    circfill(18, 18, 6, 8)
    circfill(18, 18, 5, 0)
    --top right corner
    circfill(109, 18, 6, 8)
    circfill(109, 18, 5, 0)
    --bottom left corner
    circfill(18, 109, 6, 8)
    circfill(18, 109, 5, 0)
    --bottom right corner
    circfill(109, 109, 6, 8)
    circfill(109, 109, 5, 0)
    --top line
    line(18, 12, 109, 12, 8)
    --left line
    line(12, 18, 12, 109, 8)
    --right line
    line(115, 18, 115, 109, 8)
    --bottom line
    line(18, 115, 109, 115, 8)
    --background
    rectfill(13, 18, 114, 109, 0)
    rectfill(18, 13, 109, 114, 0)

    print("leaderboard", x + 13, y, 7)
    y += 6
    for i = 1, num_columns do
        for j = 1, leaderboard_size/num_columns do
            draw_character_preview(leaderboard[leaderboard_index][1], leaderboard[leaderboard_index][2], x, y)
            --draw_character_preview(player_head_set_index, player_body_set_index, x, y)
            if leaderboard[leaderboard_index][3] > 0 then print(leaderboard[leaderboard_index][3], x + 10, y + 5, 7) end
            leaderboard_index += 1
            y += row_height
        end
        y = 6 + 16
        x += col_width
    end
end

function draw_character_preview(head_index, body_index, x, y)
    if head_index == 0 or body_index == 0 then return end
    sspr((body_index % 16) * 8 + 8 * player_frame_loop[preview_frame_index], flr(body_index / 16) * 8, 8, 8, x, y + 7, 8, 8, false, false)
    sspr((head_index % 16) * 8 + 8 * player_frame_loop[preview_frame_index], flr(head_index / 16) * 8, 8, 8, x, y + preview_head_bob_offset, 8, 8, false, false)
end

function update_leaderboard(new_score)
    new_score = flr(new_score)
    --update leaderboard
    local new_entry = {player_head_set_index, player_body_set_index, new_score}
    local added = false
    
    for i = 1, leaderboard_size do
        if leaderboard[i][3] < new_score and not added then
            --move rest of leaderboard down
            for j = leaderboard_size, i + 1, -1 do
                leaderboard[j][1] = leaderboard[j-1][1]
                leaderboard[j][2] = leaderboard[j-1][2]
                leaderboard[j][3] = leaderboard[j-1][3]
            end
            leaderboard[i][1] = player_head_set_index
            leaderboard[i][2] = player_body_set_index
            leaderboard[i][3] = new_score
            added = true
        end
    end

    --save leaderboard to cartdata
    for i = 1, leaderboard_size do
        dset((i-1)*3, leaderboard[i][1])
        dset((i-1)*3 + 1, leaderboard[i][2])
        dset((i-1)*3 + 2, leaderboard[i][3])
    end
end

function donothing()
    --do nothing
	return
end

__gfx__
00000000444444444444444444444444011111111111111000000000000066000000000000000033333333333000000011111111111000001111111111111100
000000004444444444444444444444441bbb3b3b33333131000000000666776600000000000033bbbbbbbbbbb333000017777771171000001777777117777710
007007004444444444444444444444441bb3b3b3333313110000000067777776660000000003bbbbbbb3bbbbbbbb300017111111171000001117711117111771
000770004444444444445555445555541b3b3b3333333131000000067777777777600000003b3bbbbbbb3bbbbb3bb30017100000171000000017710017100171
000770004555455445555335555313541bb3b3333333131100000667777777777776000003bbb3bb3bb3bbbb33bbb30017100000171000000017710017100171
007007005333533555333333333131351b3b33333331311100066777777777776777660003b33bbbb33bbbbbbbbbbb3017111000171000000017710017111771
00000000335335355351111111111313111111111111111100677777776777776777776003bbbbbbbbbbbbbbbbb3bb3017771000171000000017710017777710
000000005335335335133b3b3331313300133b3b3311110006777777777666667767776003bbbbbbbbb3bbb3bbb3bb3017111000171000000017710017111100
44444444b33b33b30013b3b3331311000013b3b33313110006777777777777777776776003bb3bbbbbb3bbbb333bbb3017100000171000000017710017100000
4444444433b33b3b001b3b3333313100001b3b333331310006776777767777777776776003bbb33bbb3bbbbbbbbbbb3017100000171111111117711117100000
44444444533353350013b3b3331311000013b3b33313110006777666677777777667776003bbbbb333bbbbbbbb3bbb3017100000177777711777777117100000
4444444445554554001b3b3333313100001b3b333331310006777777777777666777760003bbbbbbbbbbbbbb33bbb30011100000111111111111111111100000
44444444444444440013b3b3331311000013b3b3331311000066777777666777777660000033bbbbbb333bbbbbb3300000111100000000000000000000000000
4444444444444444001b3b3333313100001b3b333331310000006666660006666660000000003333335553333330000001777710000000000000000000000000
44444444444444440013b3b3331311000013b3b33313110000000000000000000000000000000055400550550550000017711771000000000000000000000000
4444444444444444001b3b3333313100001b3b333331310000000000000000000000000000000055500540540400000017100171000000000000000000000000
0000000000000000001bbbb3131111003b1bb3b33113113111111111111111111111111100000054540055454500000017100171000000000000000000000000
00000000000000001111111111111111b3b11111111113131dddd1ddddd1dddddd1dddd100000004450004554000000017100171000000000000000000000000
00000000000000001bbb3b3b333331315b3b3333333131351d5551d55551d555551d555100000000544005450333300017100171000000000000000000000000
00000000000000001bb3b3b333331311455553355553135411111111111111111111111100000000444009443bbbb30017100171000000000000000000000000
00000000000000001b3b3b333333313144445555445555541ddddd1ddddddd1dddddddd100000000044409403bbbb30017100171000000000000000000000000
000000000000000013b3b3333333131144444444444444441d55551d5555551d5555555100000000049494000533300017711771000000000000000000000000
00000000000000001b3b3b333331311144444444444444441d55551d5555551d5555555100000000094444004400000001777710000000000000000000000000
00000000000000000111111111111110444444444444444411111111111111111111111100000000049444444000000000111100000000000000000000000000
0000000000000000000000000000000000000000000000001dddd1ddddd1dddddd1dddd100000000094445000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000001d5551d55551d555551d555100000000049444000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000001d5551d55551d555551d555100000000094445400000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000011111111111111111111111100000000099444500000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000001ddddd1ddddddd1dddddddd100000000094445450000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000001d55551d5555551d5555555100000000949444540000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000001d55551d5555551d5555555100000000994945454000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000011111111111111111111111100000000949944545000000000000000000000000000000000000000
00000000000000000000000000008000000000000000800000000000000000000000000000055000000000000005500000000000000000000000000044444444
00000000000000000000000000005000008500000000500000e0e000000e0e0000e0e00050555505000550005055550500000000000000000000000033333333
000000000000000000000000000050000000500000005000000e0e00000e0e00000e0e00055555505055550505555550000770000007700000077000cbcccccc
00444400004444000044440000776600007766000077660000eeee0000eeee0000eeee00008888000555555000888800007007000070070000700700c3caccc5
00444300004443000044430000766b0000766b0000766b0000eee90000eee90000eee9000088a3000088a3000088a3000073b7000073b7000073b700ccc8cc55
00444a0000444a0000444a0000766600007666000076660000eee40000eee40000eee400008a4400008a4400008a4400066666600666666006666660ccccc555
00444a000444aa000044aa0000666500006665000066650000ee440000ee440000ee440000a4440000a4440000a4440066666666666666666666666633333333
00440000044000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444444
000aa000000aa000000aa000000760000007600000076000000ee000000ee000000ee000000aa000000aa000000aa00000bbbb000033330000bbbb0000000000
0088880000888a00008aa80000766605007666050076660500eeee0000eeee0000eeee0000dddd0000ddd70000d77d0000333300003333000033330000000000
0888880008888a00088aa8000075555000755550007555500eeeee000eeee7000ee77e000ddddd000dddd7000dd77d00033336300bbbb6b00333363007777770
988888aa08aa8a00aa8aa8900066660500666605006666056eeeee770e77e70077e77e609dddd5660d56670056677d900bbbb570033335700bbbb57097555577
988888aa08aa8a00aa8aa8900066660000666600006666006eeeee770e77e70077e77e609444450604546a005464a49005775550057755500577555000555500
0022200000222000002220000d55d50005d55d000d55d50000eee00000eee00000eee00000555000005550000055500053575733535757335357573300055500
99000aa000aa0000aa00990054111450541114505411145066000770007700007700660011000400001400000400110033133133bb1bb1bb3313313300055000
99000aa000aa0000aa00990005d55d000d55d50005d55d00660007700077000077006600110000400014000040001100bbbbbbbb33333333bbbbbbbb00000000
089abcd0089abcd0089abcd000000000000000000000000000000000000000000000000000000000000000000000000000000700007007000070000000000000
389abcde389abcde389abcde000000000000000000000000000000000ee733300000000000004100000054100054410000700a0000a00a0a00a0070a00000000
389abcde389abcde389abcde0000000008000000000000000ee733300e7331300ee7333000054400000454400445440009a89aa090a89aa090a89aa000000000
389abcde389abcde389abcde0888880000888800088888000e733130077333300e733130004550000044500004450000aa99a8008a99a898aa89a89807777770
087737d0087737d0087737d0001113000011130000111300077333300733330007733330004400000044000004400000944a944a944a944a944a944a97555577
007778000077780000777800001111000011110000111100073333300333333007333330005550000055500005550000a448944aa448944aa448944a00099000
0077770000777700007777000011110000111100001111000333333000000000033333300004400000044000004440008a99a9a88a99a9a88a99aa9800000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a88a08a00a8a88a0a80a88a00000000
000ee000000ee000000ee00000011000000110000001100000303300003033000030330000004400000440000004440000a8a8a0000aa00000a8a8a000000000
00eeee0000eeee0000eeee0000115100501111000511110000303000003030000030300000004400000450000000455000aa8a0000a8a800009a8a9000055000
098888000888aa00088aa9000116110061111100011111000030300000303000003030000000455000045500000005400a98aa000a90aa9000a89a0000055500
698888770877890077889960116111dd61dd1100dd11111000303000030300000030300000000540000054000000044000a908a0a8a99a000a8098a000555500
698888770877aa00778aa960161111dd61dd1100dd11111000000000000000000000000000000440000004400000044008a98a800a89a8a000a98a8007555570
00ddd00000ddd00000ddd0000055500000555000005550000000000000000000000000000050044005000440500054400a80088008a08a8008a0a80097777777
22200888008880008880222011000dd000dd0000dd00110000000000000000000000000000545440054454405444550008000000000000800000000000009000
22200888008880008880222011000dd000dd0000dd00110000000000000000000000000000045500004455000444400000000080080000000000008000090000
62727272727272727272727272727282010101010101010101010101010101016272727272727272727272727272728201010101010101010101010101010101
62727272727272727272727272727282010101010101010101010101010101016272727272727272727272727272728201010101010101010101010101010101
63737373737373737373737373737383101010101010101010101010101010106373737373737373737373737373738310101010101010101010101010102030
63737373737373737373737373737383101010102030101010101010101010106373737373737373737373737373738310101010101020301010101010102030
00000000000000213100000000000000000062727272727272820000000000000063737373737373737373737373738300000000000000000000000000002131
63737373737373737373738300000000000000002131000000000000000000006373738300000000006373737373738300000000000021310000000000002131
00000000000000213100000000000000000000637373737373830000000000000000637373737373737373737373738300000000000000000000000000002131
63737373737373737373738300000000000000002131000000000000000000006373830000000000000063737373738300000000000021310000000000002131
00000000000000213100000000000000000000006373737373830000000000000000006373737373737373737373738300000000000000000000000000002131
63737373737373737373738300000000000000002131000000000000000000006373830000000000000063737373738300000000000021310000000000002131
00000000000000223200000000000000000000000063737373830000000000000000000000000000000000006373738300000000000000000000000000002131
63737373737373737373830000000000000000002232000000000000000000006373830000000000000000637373738300000000000021310000000000002131
00000000000000000000000000000000000000000000637373830000000000000000000000000000000000000063738300000000000000000000000000002131
63737373737373737373830000000000000000000000000000000000000000006383000000006282000000637373738300000000000022320000000000002131
62000000000000000000000000000082000000000000006373830000000040506200000000000000000000000000638362727282000000000040500000002131
63737383000063737373000000004050000000000000000000000000000040506383000000006383000000006373738300000000000000000000000000002131
63820000000000000000000000006283000000000000000063830000000041516382000000000040500000000000008363737383000000000041510000002131
63830000000000006383000000004151000000000000000000000000000041516383000000627383000000000000008300000000000000000000000000002232
63830000000062727282000000006383000000000000000000000000000041516373820000000041510000000000000000000000006272727272820000002232
00000000000000000000000000004151000000000000000062728200000041510000000000637373820000000000000000000000000000000000000000000000
63738200000000000000000000627383000000000000000000000000000041516373738200000041510000000000000000000000006373737373830000000000
00000000000000000000000000004151000000000000000063738300000041510000000062737373830000000000000000000000000000000000000000000000
63738300000000000000000000637383000000000000000000000000000041516373737372727272727272728200000000000000000000000000000000000000
00000000000000000000000000004151000000000000000000000000000041510000000063737373830000000000000000000000006272728200000000000000
63737382000000000000000062737383000000000000000000000000000041516373737373737373737373737382000000000000000000000000000000000000
00000000405000000000000000004151000062728200000000000000000041510000006273737373738200000000000000000000627373737382000000000000
63737373727272727272727273737383000000000000000000000000000041516373737373737373737373737373820000000000000000000000000000000000
00000000415100000000000000004151000063738300000000000000000041510000006373737373738300000000000000000062737373737373820000000000
63737373737373737373737373737383111111111111111111111111111142526373737373737373737373737373738211111111111111111111111111111111
62727272727272727272727272727282111111111111111111111111111142526272727373737373737372727272728211111111111111111111111111111111
63737373737373737373737373737383010101010101010101010101010101016373737373737373737373737373738301010101010101010101010101010101
63737373737373737373737373737383010101010101010101010101010101016373737373737373737373737373738301010101010101010101010101010101
62727272727272727272727272727282010101010101010101010101010101016272727272727272727272727272728201010101010101010101010101010101
62727272727272727272727272727282010101010101010101010101010101016272727272727272727272727272728201010101010101010101010101010101
63737373737373737373737373737383101010101010102030101010101010106373737373737373737373737373738310101010101010101010101010102030
63737373737373737373737373737383101010101010101010101010101010106373737373737373737373737373738310101010101010203010101010102030
00002131000000000000000021310000000000000000002131000000000000000000000063737373737373737373738300000000000000000000000000002131
63830000000000000000213100000000000000000000000000000000000000006373737373737373737373737373738300000000000000213100000000002131
00002232000000000000000022320000000000000000002131000000000000000000000000637373830000006373738300000000000000000000000000002131
63830000000000000000223200000000000000000000000000000000000000006373737373737373737373737373738300000000000000213100000000002131
00000000000000000000000000000000000000000000002232000000000000000000000000637383000000000063738300000000000000000000000000002131
63830000000000000000000000000000000000000000000000000000000000006373737373737373737373737373738300000000000000213100000000002131
00000000000000405000000000000000000000000000000000000000000000000000000000638300000000000000638300000000000000004050000000002131
63830000000000000000000000000000627272728200000000000000000000006373737373737373737373737373738300000000000000213100000000002131
00000000000000415100000000000000000000000000000000000000000000000000000000638300000000000000638300000000006272727282000000002131
63830000000000000000000000000000637373738300000000000000000000006373737373737373737373737373738300000000000000223200000000002131
62727272727272727272727272727282000000000000000000000000000040506282000000638300000000000000638362728200006373737383000000002131
63830000000000000000000000006282000000000000000000000000000040506373737373737373737373737373738300000000000000000000000000002131
63737373737373737373737373737383000000000000000000000000000041516383000000000000000000000000638363738300000000000000000000002131
63830000006282000000000000006383000000000000000000000000000041516373737373737373737373737373738300000000000000000000000000002232
63737373737373737373737373737383000000000000004050000000000041516383000000000000000000000000000000000000000000000000000000002131
00000000006383000000000000006383000000000000000000000000000041510000000000000021310000000000000000000000000000000000000000000000
63737373737373737373737373737383000000000000004151000000000041516383000000000000000000000000000000000000000000004050000000002131
00000000006383000000000000006383000000000000000000000000000041510000000000000022320000000000000000000000000000000000000000000000
63737373737373737373737373737383000000000000004151000000000041516383000000000000000040500000000000000000000000004151000000002232
00000000006373820000000000627383000000004050000000000000000041510000000000000000000000000000000000000000000000405000000000000000
63737373737373737373737373737383000000000000004151000000000041516383000000000000000041510000000000000000000000004151000000000000
00000000006373738200000062737383000000004151000000000000000041510000405000000000000000004050000000000000000000415100000000000000
63737373737373737373737373737383000000000000004151000000000041516383000000000000000041510000000000000000000000004151000000000000
00000000627373737372727273737383000000004151000000000000000041510000415100000000000000004151000000000000000000415100000000000000
63737373737373737373737373737383111111111111114252111111111142526373727272727272727272727272728211111111111111114252111111111111
62727272737373737373737373737383111111114252111111111111111142526272727272727272727272727272728211111111111111425211111111111111
63737373737373737373737373737383010101010101010101010101010101016373737373737373737373737373738301010101010101010101010101010101
63737373737373737373737373737383010101010101010101010101010101016373737373737373737373737373738301010101010101010101010101010101
__gff__
0001010101010000000000000000000001010101010100000000000000000000000001010101010101000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2200000000000000000000000000002222000000000000000000000000000022220000000000000000000000000000222200000000000000000000000000002222000000000000000000000000000022220000000000000000000000000000222200000000000000000000000000002222000000000000000000000000000022
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
2627272727272727272727272727272810101010101010101010101010101010262727272727272727272727272727281010101010101010101010101010101026272727272727272727272727272728101010101010101010101010101010102627272727272727272727272727272810101010101010101010101010101010
3637373737373737373737373737373801010101010101020301010101010101363737373737373737373737373737380101010102030101010101010101020336373737373737373737373737373738010101010101010101020301010101013637373737373737373737373737373801010101010101010101010101010203
0036373737373737373737373737380000000000000000121300000000000000000036373737373737373737373737380000000012130000000000000000121336373737373737373737373737380000000000000000000000121300000000003637373737373737373737373737373800000000000000000000000000001213
0000363737373737373737373738000000000000000000121300000000000000000000003637373737373737373737380000000012130000000000000000121336373737373737373737373800000000000000000000000000121300000000003637373737380000000036373737373800000000000000000000000000001213
0000003637373737373737373800000000000000000000121300000000000000000000000000363737373737373737380000000012130000000000000000121336373737373737373738000000000000000000000000000000121300000000003637373738000000000000363737373800000000000000000000000000001213
0000000036373737373737380000000000000000000000121300000000000000000000000000000036373737373737380000000012130000000000000000121336373737373737380000000000000000000000000000000000121300000000003637373800000000000000003637373800000000000000000000000000001213
0000000000363737373738000000000000000000000000121300000000000000000000000000000000003637373737380000000012130000000000000000121336373737373800000000000000000000000000000000000000121300000000003637380000000000000000000036373800000000000000000000000000001213
2600000000003637373800000000002800000000000000121300000000000405262800000000000000000000363737380000000012130000000000000000121336373738000000000000000000002628000000000405000000121300000004053638000000000026280000000000363800000000000004050000000000001213
3628000000000000000000000000263800000000000000121300000000001415363727280000000000000000000036380000000022230000000000000000222336380000000000000000000026273738000000001415000000222300000014153600000000002637372800000000003800000000000014150000000000002223
3637280000000000000000000026373800000000000000222300000000001415363737372728000000000000000000000000000000000000000000000000000000000000000000000000262737373738000000001415000000000000000014150000000000263737373728000000000000000000000014150000000000000000
3637372800000000000000002637373800000000000000000000000000001415363737373737272800000000000000000000000000000000000000000000000000000000000000002627373737373738000000001415000000000000000014150000000026373737373737280000000000000000000014150000000000000000
3637373728000000000000263737373800000000000000000000000000001415363737373737373727280000000000000000000000000000000000000000000000000000000026273737373737373738000000001415000000000000000014150000002637373737373737372800000000000000000014150000000000000000
3637373737280000000026373737373800000000000000000000000000001415363737373737373737372728000000000000000000000000000405000000000000000000262737373737373737373738000000001415000000000000000014150000263737373737373737373728000000000000000014150000000000000000
3637373737372727272737373737373800000000000000000000000000001415363737373737373737373737272800000000000000000000001415000000000000002627373737373737373737373738000000001415000000000000000014150026373737373737373737373737280000000000000014150000000000000000
3637373737373737373737373737373811111111111111111111111111112425363737373737373737373737373727281111111111111111112425111111111126273737373737373737373737373738111111112425111111111111111124252637373737373737373737373737372811111111111124251111111111111111
3637373737373737373737373737373810101010101010101010101010101010363737373737373737373737373737381010101010101010101010101010101036373737373737373737373737373738101010101010101010101010101010103637373737373737373737373737373810101010101010101010101010101010
__sfx__
000100000e0260b0260a0260d006090061210614106111060f6060960605606026060160601606007070070700707007070070700707007070070700707007070070700707007070070000700007000170000000
000100000d0300e030100301303017030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000097300c73012730157301b730207001f70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000370602f06029050220501d05017040140400e04009040050400203000030000200002000020000200000000000176001460012600106000d6000b600086003c0002d000240001b000140000d00008000
000100002305023050230500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000090500c050100501805022050350502d05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
