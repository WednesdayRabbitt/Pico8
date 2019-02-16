pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--init--
function _init()
	--challenge mode
	hard_mode=false
	game_mode = "title"
	--title screen low resolution
	poke(0x5f2c,3)
	sine_timer=0
	code_count=1
	slow_code_count=1
	--camera position
	cam_x = 0
	cam_y = 0
	cam_goal_y=0
	scroll_spd=3
	scroll_dir="verti"
	scroll_lenience=8
	--map size in tiles
	map_w = 128
	map_h = 64
	--room size in tiles
	room_w = 16
	room_h = 8
	--total number of rooms in game
	rooms_num = 64
	--init transition speeds
	init_transitions()
	draw_init()
	save_rooms()

	init_actors()
	init_partics()

	fall_spd=0.3
	max_grav=3

	keys=0
	eggs=0
	deaths=0
	--item_move_down=16
	boss_gate_timer=0

	max_hp=6
	hp=6
	fireball_timer=0
	charge_time=20

	init_plr()
	explored_rooms={}
	for x=0,23 do
		explored_rooms[x]={}
	end
	--respawn position
	check_room_x=2
	check_room_y=8
	check_scroll_dir="verti"
	check_room_pal=0

	--a word on the screen
	word=""
	word_timer=0

	--timer for get item anim
	item_wait=0
	--time to respawn
	respawn_timer=-1
	--a delightful transition
	wipe_transition=0
end

--sets up the actor system
function init_actors()
	actors = {}
end

function new_actor(x,y,s)
	local a = {}
	a.x=x --position
	a.y=y
	a.s=s --sprite
	a.f=false --flip
	return a
end

function add_actor(a)
	add(actors,a)
end

--sets up the particle system
function init_partics()
	partics = {}
end

function new_partic(x,y,c,l)
	local p = {}
	p.x=x --position
	p.y=y
	p.c=c --colour
	p.life=l
	p.lived_for=0
	return p
end

function add_partic(p)
	add(partics,p)
end

function init_plr()
	plr = new_actor(20,48,38)
	plr.egg=true
	plr.mom=0
	plr.acc=0.25
	plr.dcc=0.4
	plr.max_mom=1
	plr.up=0
	plr.anim=0
	plr.grav=0
	plr.spin=-1

	plr.name="plr"
	add_actor(plr)
end

--copies the rooms into memory.
function save_rooms()
	rooms={}
	local room_cur=0
	local room_x=0
	local room_y=0
	while room_cur<=rooms_num do
		active_room={}
		active_room["up"]="open"
		active_room["down"]="open"
		active_room["left"]="wall"
		active_room["right"]="wall"
		active_room["left_stop"]=false
		active_room["right_stop"]=false
		for x=0,room_w-1 do
			active_room[x]={}
			for y=0,room_h-1 do
				tx=room_x*room_w+x
				ty=room_y*room_h+y
				tile=mget(tx,ty)
				active_room[x][y]=tile
				if tile==31 then
					active_room["up"]="wall"
				elseif tile==47 then
					active_room["down"]="wall"
				elseif tile==77 then
					active_room["save"]=true
				elseif tile==48 then
					active_room["item"]=true
				elseif tile==62 then
					active_room["left_stop"]=true
				elseif tile==63 then
					active_room["right_stop"]=true
				elseif x==0 and not fget(tile,0) then
					active_room["left"]="open"
				elseif x==15 and not fget(tile,0) then
					active_room["right"]="open"
				end
				mset(tx,ty,0)
			end
		end
		rooms[room_cur]=active_room
		room_cur+=1
		room_x+=1
		if room_x==8 then
			room_x=0
			room_y+=1
		end
	end
end

function load_room(num,cx,cy,e_lv,door)
	to_play_music=2
	if e_lv==nil then e_lv=0 end
	room=rooms[num]
	if room == nil then
		return false
	end
	for x=0,room_w-1 do
		for y=0,room_h-1 do
			tile=room[x][y]
			if y>0 then
				above_tile=room[x][y-1]
			else
				above_tile=0
			end
			if x>0 then
				next_tile=room[x-1][y]
			else
				next_tile=0
			end
			if above_tile==68 or above_tile==69 then
				above_tile=137-above_tile
			end
			if next_tile==68 or next_tile==69 then
				next_tile=137-next_tile
			end
			act=load_actor(tile,(x+cx)*8,(y+cy)*8,e_lv)
				--already broken blocks
			if door and fget(tile,7) then
				mset(cx+x,cy+y,next_tile)
			elseif door and fget(tile,3) then
			 mset(cx+x,cy+y,85)
			elseif act==nil then
				mset(cx+x,cy+y,tile)
			else
				if act.name=="room_top" or act.name=="room_bottom" or act.name=="slime" then
					mset(cx+x,cy+y,next_tile)
				elseif act.name=="block" then
					mset(cx+x,cy+y,tile)
				else
					mset(cx+x,cy+y,above_tile)
				end
				add_actor(act)
			end
		end
	end
	play_music(to_play_music)
	return true
end

function load_actor(i,x,y,e_lv)
	a=nil
	local item_id=rm_items[room_y][room_x]
	if i==62 then
		a=new_actor(x,y,15)
		a.name="exit_left"
	elseif i==63 then
		a=new_actor(x,y,15)
		a.name="exit_right"
	elseif i==31 then
		a=new_actor(x,y,15)
		a.name="room_top"
	elseif i==47 then
		a=new_actor(x,y,15)
		a.name="room_bottom"
	elseif i==48 then
		a=new_actor(x+4,y,15)
		if (item_id=="h") a.s=48
		if (item_id=="1") a.s=49
		if (item_id=="2") a.s=50
		if (item_id=="3") a.s=51
		if (item_id=="4") a.s=52
		if (item_id=="k") a.s=53
		if (item_id=="e") a.s=54+eggs
		a.name="item"
		to_play_music=8
		if a.s!=15 then
			a.g={}
 		a.g[0]=new_actor(x,y-4,58)
 		a.g[1]=new_actor(x+8,y-4,58)
 		a.g[2]=new_actor(x,y+4,58)
 		a.g[3]=new_actor(x+8,y+4,58)
 		for n=0,3 do
 			a.g[n].f=n%2==1
 			a.g[n].vf=n>1
 			a.g[n].name="glow"
 			add_actor(a.g[n])
 		end
 		a.timer=1
 	end
		if a.s==15 then a.name="" end
	elseif i==77 then
		a=new_actor(x,y+8,93)
		a.name="savepart"
		add_actor(a)
		a=new_actor(x+8,y+8,94)
		a.name="savepart"
		add_actor(a)
		a=new_actor(x+8,y,78)
		a.name="savepart"
		add_actor(a)
		a=new_actor(x,y,77)
		a.name="save"
		to_play_music=8
	elseif i==79 then
		a=new_actor(x,y,79)
		a.name="block"
	elseif i==16 or i==17 then
		a=new_actor(x,y,16)
		--set the direction.
		a.f=i==17
		a.name="beetle"
		a.enemy=true
	elseif i==18 then
		init=y-y%64+53
		a=new_actor(x,init,19)
		a.init=init
		a.hop=y
		a.state="wait"
		a.name="jellyfish"
		a.enemy=true
		a.anim=0
	elseif i>=74 and i<=76 then
		a=new_actor(x+4,y,74)
		a.name="bat"
		a.enemy=true
		a.len=(i-72)*10
		a.pause=10
		a.goal_x=a.x
		a.goal_y=a.y
		a.sine_timer=rnd(100)/100
		to_lock_room=true
		if item_id==0 then
			a.s=15
			a.name="killme"
		else
			to_play_music=9
		end
	elseif i==20 or i==21 then
		a=new_actor(x,y,20)
		--set the direction.
		a.vf=i==21
		a.name="slime"
		a.enemy=true
	elseif i==34 then
		a=new_actor(x,y,35)
		--set the direction.
		a.name="skeleton"
		a.enemy=true
		a.mom=0
		a.anim=0
		a.up=0
		if e_lv>0 then
 		a.skull=new_actor(x,y-5,34)
 		a.skull.name="skull"
 		a.skull.enemy=true
 		a.skull.body=a
 		a.skull.grav=0
 		a.grav=0
 		a.skull.hp=e_lv
 		add_actor(a.skull)
		end
	end
	if a!=nil and a.enemy then
		a.max_hp=e_lv
		a.hp=e_lv
		a.lv=e_lv
		a.damage=e_lv
		if e_lv>2 then
			a.pal="white"
		elseif e_lv>1 then
			a.pal="red"
		elseif e_lv==0 then
			a.name="killme"
			a.s=15
		end
	end
	return a
end

function init_transitions()
	tr_length = 10
	tr_steps =
	{2,2,4,8,16,16,8,4,2,2}
	tr_pos = -1
end

function init_rooms()
	local rooms_list=split_string("006641421047002731144630000000371041425500000000,006500000000000000001100000000000000005400000000,007610404152424041603241562550511041425341420700,000000000000000000000000001100000000000000000000,002102062022252324261031041600371067002741426100,001107000000150000000000001500000065000000007500,001217101314160027333434353240610076415252426400,000000000000150000000000000000150000000000006500,000001020304050206070021026214056325505110407700,000000000000000000000015000000000011000000000000,000000664142550027414245415646300043415256463000,003710640000540000000000000011000015000000110000,000000764142531057703434343532415644002740450700")
	local col_list=split_string("01111104411-000666660000,010000000010000000060000,01111111111-5-6666666660,000000000000050000000000,0233-41111-5550888088880,022000100000050008000080,02211110555555-708888880,000000100000000700000080,0011111111077777-8888880,000000000007000007000000,000999907777-111077-1110,099900900000001007000100,0009999999---11177011110")
	local item_list=split_string("0|--|e0k--|-000e|--|0000,0|00000000|00000000|0000,0|-|---|-!|--|-/|--|--h0,0000000000000|0000000000,0|--|-|---|--|0e-|0h--|0,0|h000|000000|000|0000|0,0|2|--|0h----|-|0|----|0,000000|00000000|000000|0,00|---|--10|---|-|-/|-|0,00000000000|00000|000000,000|--|0k--|--|-0|---|-0,0e-|00|0000000|00|000|00,000|--|-/-----|--|03-|k0")
	local enemy_list=split_string("x00001x01200xxx11111xxxx,x0xxxxxxxx0xxxxxxxx1xxxx,x0012221030100000111220x,xxxxxxxxxxxxx0xxxxxxxxxx,x1111201120120x101x0220x,x10xxx0xxxxxx0xxx1xxxx0x,x111100x02222202x021100x,xxxxxx0xxxxxxxx0xxxxxx0x,xx00000000x022203100011x,xxxxxxxxxxx0xxxxx1xxxxxx,xxx1110x02101000x102010x,x100xx0xxxxxxx0xx1xxx1xx,xxx022100121212012x0220x")

	if hard_mode then
		rooms_list=split_string("002150514700002170343434262502620667000000000000,001500006641601600000000007150516776311446400700,007150517700001100374067000000006500000043300000,002102620640104400000076415252427310070011000000,001241422022255051670000000000000000000012206100,000000000000156630744020415252562570343434351600,000027101314167420734142670000001500000000001100,000000000000157641524267650066405320612731141600,000001020304050206073777650072214142442102044400,000000000037414267000000650072124142074340670000,002761000021505164006640731073572502041600720000,000011000011000076306527414261001100001500720000,000071020432201031067370342632204400001220730700")
		col_list=split_string("011110011111111112000000,0100111100000999922-3330,011110010999000090003300,032222110009999999903000,0333-41aa600000000003-40,0000001666aaaaaaa-----40,0001111666666000a0000040,000000166666606aa-644440,001111111166606aa661--40,000008888000606a66611100,07700788806666-aa1110100,007007008865555010010100,007777--5666555-10011110")
 	item_list=split_string("0|-/e00|-----|---|000000,0|00|-!|00000|-/||--|-k0,0|-/|00|0e-|0000|000|-00,0|---|-|000|----|-k0|000,0|--|-|-/|0000000000|-|0,000000||-|-|----|-----|0,00k|--||-|--|000|00000|0,000000||---||0|-|-|k--|0,00|---|--1e||0||--||--|0,00000e--|000|0||--3|-|00,0k|00|-/|0|-|-|/|--|0|00,00|00|00|-|k--|0|00|0|00,00|--|-|--|---|-|00|-|20")
		enemy_list=split_string("x3002xx33333333332xxxxxx,x3xx3002xxxxx2002233230x,x3003xx2x230xxxx2xxx20xx,x2222302xxx22322200x3xxx,x222022012xxxxxxxxxx323x,xxxxxx02002020300232322x,xxx1100022220xxx0xxxxx2x,xxxxxx0203022x022020222x,xx00000000200x022222330x,xxxxx2222xxx2x02220220xx,x02xx2222x2000002230x0xx,xx3xx2xx2220222x2xx2x0xx,xx222200120223202xx2020x")
	end
	room_x=2
	room_y=8
	lay_w=24
	lay_h=13
	layout={}
	rm_cols={}
	rm_items={}
	rm_enemies={}
	rm_doors={}
	for i=0,lay_h-1 do
		layout[i]={}
		rm_cols[i]={}
		rm_items[i]={}
		rm_enemies[i]={}
		str=rooms_list[i+1]
		col_str=col_list[i+1]
		item_str=item_list[i+1]
		enemy_str=enemy_list[i+1]
		rm_doors[i]={}
		for j=0,lay_w-1 do
			num=to_num(sub(str,j*2+2,j*2+2))
			num+=8*to_num(sub(str,j*2+1,j*2+1))
			layout[i][j]=num
			col=sub(col_str,j+1,j+1)
			rm_cols[i][j]=col
			item=sub(item_str,j+1,j+1)
			rm_items[i][j]=item
			enemy=sub(enemy_str,j+1,j+1)
			rm_enemies[i][j]=to_num(enemy)
			rm_doors[i][j]=false
		end
	end
end

function split_string(s)
	ret={}
	count=1
	str=""
	for i=1,#s do
		char=sub(s,i,i)
		if char=="," then
			ret[count]=str
			str=""
			count+=1
		else
			str=str..char
		end
	end
	ret[count]=str
	return ret
end

function to_num(c)
	for i=1,9 do
		if sub("123456789",i,i)==c then
			return i
		end
	end
	return 0
end
-->8
--update--

function _update60()
	sine_timer+=0.01
	sine_timer=sine_timer%1
	if win then
 	word="you win!        "
 	plr.s=1
 	if deaths==0 then
 		word_col=11
 	end
		return
	end
	if game_mode=="title" then
		update_title()
		return
	end

	if open_gate then
		update_gate()
		return
	end
	explored_rooms[room_x][room_y]=scroll_dir
	if respawn_timer>0 then
		respawn_timer-=1
	elseif respawn_timer==0 then
		respawn_timer=-1
		respawn()
	end
	if wipe_transition>0 then
		wipe_transition-=8
		return
	end
	if item_wait>0 then
		item_wait-=1
		if item_wait==0 then
			if plr.grav<0 then
				plr.grav=0
			end
			play_music(8)
		end
		return
	end
	if update_tr() then
		if update_boss_gate() then
 		update_plr()
 		update_actors()
 		update_cam()
 		update_partics()
		end
	end
end

function update_boss_gate()
	if (boss_gate_timer==0) return true
	boss_gate_timer-=1
	if plr.x>cam_x+64 then
		plr.x-=0.5
	else
		plr.x+=0.5
	end

 lock_room()

	return false
end

function lock_room()
	local cx=cam_x/8
	local cy=cam_y/8
	local i=cy+boss_gate_timer/3
	if mget(cx,i)==85 then
		mset(cx,i,91)
	elseif mget(cx+15,i)==85 then
		mset(cx+15,i,91)
	end
end

function update_title()
	for i=0,7 do
 	x=rnd(64)
 	p=new_partic(x,64+abs(x-32)/8,7,16+rnd(24))
 	p.yv=-0.3-rnd(5)/20
 	p.xv=rnd(10)/20-0.25
 	p.hard=hard_mode
 	add_partic(p)
	end
	if btnp(5) then
		game_mode="game"
		poke(0x5f2c,0)
		partics={}
		init_rooms()
		load_room(layout[room_y][room_x],0,0)
		play_music(8)
	end
	code={3,3,0,3,1}
	if btnp(code[code_count]) then
		code_count+=1
		if code_count>5 then
			sfx(22)
 		hard_mode=not hard_mode
 		code_count=1
 		foreach(partics,fire_go_big)
		end
	elseif btnp(0) or btnp(1) or btnp(2) or btnp(3) then
		code_count=1
	end
	update_partics()
	foreach(partics,colour_fire)
end

function colour_fire(p)
	colour_fire_all(p,10,9,8)
	if p.hard then
	 colour_fire_all(p,10,11,3)
 end
end

function colour_fire_all(p,c1,c2,c3)
 fire_col_check(7,c1,p)
 fire_col_check(16,c2,p)
 fire_col_check(32,c3,p)
end

function fire_go_big(p)
	p.yv=-p.yv/2
end

function fire_col_check(x,c,p)
 if(p.lived_for>x) p.c=c
end

function mom_by_arrows(a)
	if btn(1) and not btn(0) then
		a.mom+=a.acc
	elseif btn(0) and not btn(1) then
		a.mom-=a.acc
	else
		if a.mom>a.dcc then
			a.mom-=a.dcc
		elseif a.mom<-a.dcc then
			a.mom+=a.dcc
		else
			a.mom=0
		end
	end
	if a.mom>a.max_mom then
		a.mom=a.max_mom
	elseif a.mom<-a.max_mom then
		a.mom = -a.max_mom
	end
end

function is_solid(x,y)
	return is_flag_set(x/8,y/8,0)
end

function is_gate(x,y)
	return is_flag_set(x/8,y/8,3)
end

function is_lava(x,y)
	return is_flag_set(x/8,y/8,2)
end

function is_flag_set(x,y,f)
	return fget(mget(x,y),f)
end

function update_mom(a)
	if a.mom == nil then return end
	a.x+=a.mom
	if a.fly!=nil then
		if a.fly<0 then
			a.x-=1
			a.fly+=1
		elseif a.fly>0 then
			a.x+=1
			a.fly-=1
		end
	end
	if is_in_wall(a) then
		while is_in_wall(a) do
			local f=0
			if a.fly!=nil then
				f=a.fly
			end
			if a.mom+f<0 then
				a.x+=1
			else
				a.x-=1
			end
		end
		a.mom=0
		if a.fly!=nil then
			a.fly=0
		end
	end
end

function gravity(a)
if a.grav==nil then return end
	a.grav+=fall_spd
	if a.grav>=max_grav then
		a.grav=max_grav
	end
	a.y+=a.grav
	if is_in_wall(a) then
		while is_in_wall(a) do
			if a.grav>0 then
				a.y-=1
			else
				a.y+=1
			end
		end
		a.grav=0
	end
end

function is_in_wall(a)
	return is_solid(a.x,a.y) or
								is_solid(a.x+7,a.y) or
								is_solid(a.x,a.y+7) or
								is_solid(a.x+7, a.y+7)
end

function is_on_ground(a)
 return is_solid(a.x,a.y+8) or
 							is_solid(a.x+7,a.y+8)
end

function update_cam()
	if tr_pos!=-1 then return end
	if scroll_dir=="horiz" then
		prev_cam_x=cam_x
		local dist=cam_x-plr.x+60
		while dist>scroll_lenience do
			cam_x-=1
 		dist=cam_x-plr.x+60
 	end
		while dist<-scroll_lenience do
			cam_x+=1
 		dist=cam_x-plr.x+60
 	end
 	for a in all(actors) do
 		if a.name=="exit_left" then
 			if cam_x<a.x then
 				cam_x=a.x
 			end
 		elseif a.name=="exit_right" then
 			if cam_x>a.x-120 then
 				cam_x=a.x-120
 			end
 		end
 	end
 	if flr((cam_x+64)/128)!=flr((prev_cam_x+64)/128) then
 		if cam_x>prev_cam_x then
 			room_x+=1
 		else
 			room_x-=1
 		end
 	end
 else
		--save previous cam pos.
		prev_cam_y=cam_y
 	--vertical cam movement
 	if is_on_ground(plr) or
 				plr.y-40>cam_goal_y then
 		cam_goal_y=plr.y-40
 	end
 	if cam_goal_y+scroll_spd<cam_y then
 		cam_y-=scroll_spd
 	elseif cam_goal_y-scroll_spd>cam_y then
 		cam_y+=scroll_spd
 	else
 		cam_y=cam_goal_y
 	end
 	--stop at room top and bottom
 	for a in all(actors) do
 		if a.name=="room_top" then
 			if cam_y<a.y then
 				cam_y=a.y
 			end
 		elseif a.name=="room_bottom" then
 			if cam_y>a.y-56 then
 				cam_y=a.y-56
 			end
 		end
 	end
 	--update room_y
 	if flr((cam_y+32)/64)!=flr((prev_cam_y+32)/64) then
 		if cam_y>prev_cam_y then
 			room_y+=1
 		else
 			room_y-=1
 		end
 	end
	end
end

function cam_out_room_top()
	for i=0,15 do
		if not is_solid(i*8,cam_y+1) then
			return false
		end
	end
	return true
end

function cam_out_room_bottom()
	for i=0,15 do
		if not is_solid(i*8,cam_y+63) then
			return false
		end
	end
	return true
end

--rng for explosions
function explode_rnd()
	return rnd(0.5)+0.75
end

function update_partics()
	for p in all(partics) do
		update_partic(p)
	end
end

function update_partic(p)
	p.life-=1
	p.lived_for+=1
	if p.life<=0 then
		del(partics,p)
	else
		if p.xv!=nil then
			p.x+=p.xv
			if is_solid(p.x,p.y) then
				p.xv=-p.xv/2
				if p.xv>0 and p.xv<1 then
					p.xv=1
				end
				p.x+=p.xv
			end
			p.y+=p.yv
			if is_solid(p.x,p.y) then
				p.yv=-p.yv/2
				if p.yv>0 and p.yv<1 then
					p.yv=1
				end
				p.y+=p.yv
			end
			if is_solid(p.x,p.y) then
				del(partics,p)
			end
			if p.xa!=nil then
				p.xv+=p.xa
				p.yv+=p.ya
			end
		end
	end
end

--update transitions
function update_tr()	--exit if not started
	if tr_pos == -1 then
		return true
	else
	item_move_down=0
		--increase position
		tr_pos+=1
		--move in correct direction
		if tr_dir == "right" then
			cam_x+=tr_steps[tr_pos]*2
		elseif tr_dir == "left" then
			cam_x-=tr_steps[tr_pos]*2
		elseif tr_dir == "down" then
			cam_y+=tr_steps[tr_pos]
		elseif tr_dir == "up" then
			cam_y-=tr_steps[tr_pos]
		end
	end
	--stop at the end.
	load_new_room()
	return false
end

function load_room_special(i,j,x,y)
	return load_room(layout[j][i],x,y,rm_enemies[j][i],rm_doors[j][i])
end

function load_new_room()
	if tr_pos>=tr_length then
		tr_pos = -1
		actors={plr}
		partics={}
		if scroll_dir=="horiz" then
 		if tr_dir == "right" then
 			local i=0
 			local continue=true
 			while continue do
				rm=load_room_special(room_x+i,room_y,room_w*i,0)
				i+=1
 				for a in all(actors) do
 					if a.name=="exit_right" then
 						continue=false
 					end
 					if rm==false then
 						continue=false
 					end
 				end
 			end
  		plr.x=((plr.x+4)%(room_w*8))-4
  		plr.y=((plr.y)%(room_h*8))
  		cam_x=0
  		cam_y=0
  		clear_tr_area()
 		elseif tr_dir == "left" then
 			local i=0
 			local continue=true
 			while continue do
 			rm=load_room_special(room_x+i,room_y,112+room_w*i,0)
 				i-=1
 				for a in all(actors) do
 					if a.name=="exit_left" then
 						continue=false
 					end
 					if rm==false then
 						continue=false
 					end
 				end
 			end
  		plr.x=((plr.x+4)%(room_w*8))-4+112*8
  		plr.y=((plr.y)%(room_h*8))
  		cam_x=112*8
  		cam_y=0
  		clear_tr_area()
  	end
	 else
	 rm=load_room_special(room_x,room_y,0,room_h*3)
 		local origin=3
 		local top=false
 		local bot=false
 		for a in all(actors) do
 			if a.name=="room_top" then
 				origin=0
 				top=true
 				break
 			elseif a.name=="room_bottom" then
 				origin=6
 				bot=true
 				break
 			end
 		end

 		if top or bot then
 			clear_side_row()
 			actors={plr}
 			partics={}
 			rm=load_room_special(room_x,room_y,0,room_h*origin)
 		end

 		if not top then
 			local i=-1
 			local continue=true
 			while continue do
 				if (room_y+i)<0 then continue=false end
 				for a in all(actors) do
 					if a.name=="room_top" then
 						continue=false
 					end
 				end
 				if continue then
 				rm=load_room_special(room_x,room_y+i,0,room_h*(i+origin))
 					if rm==nil then
 						continue=false
 					end
 				end
 				i-=1
 			end
 		end
 		if not bot then
 			local i=1
 			local continue=true
 			while continue do
 				if (room_y+i)<0 then continue=false end
 				for a in all(actors) do
 					if a.name=="room_bottom" then
 						continue=false
 					end
 				end
 				if continue then
 				rm=load_room_special(room_x,room_y+i,0,room_h*(i+origin))
 					if rm==nil then
 						continue=false
 					end
 				end
 				i+=1
 			end
 		end

  	plr.x=((plr.x+4)%(room_w*8))-4
  	plr.y=((plr.y)%(room_h*8))+(origin*8*room_h)
  	cam_x=0
  	cam_y=room_h*origin*8
 		clear_tr_area()
 	end
 end
end

function clear_top_row()
	for i=0,127 do
		for j=0,7 do
			mset(i,j,0)
		end
	end
end

function clear_side_row()
	for i=0,15 do
		for j=0,55 do
			mset(i,j,0)
		end
	end
end

function clear_tr_area()
	for i=16,63 do
		for j=8,15 do
			mset(i,j,0)
		end
	end
end

function tr_start(direct)
	--tr starts
	tr_pos=0
	--set the direction
	tr_dir=direct
	--move camera to tr area
	cam_x=room_w*16
	cam_y=room_h*8
	--move the plr to tr area
	plr.x=((plr.x+4)%(room_w*8))+room_w*16-4
	plr.y=((plr.y)%(room_h*8))+room_h*8
	--copy this room to tr area
	local this_room=layout[room_y][room_x]
	load_room(this_room,room_w*2,room_h,0,true)
	--based on direction...
	if direct=="right" then
		plr.x+=room_w*8
		local next_room=layout[room_y][room_x+1]
		load_room(next_room,room_w*3,room_h,0,true)
		room_x+=1
	else
		plr.x-=room_w*8
		local next_room=layout[room_y][room_x-1]
		load_room(next_room,room_w,room_h,room_h,0,true)
		room_x-=1
	end
	actors={plr}
	partics={}
	if scroll_dir=="horiz" then
		scroll_dir="verti"
		clear_top_row()
	else
		scroll_dir="horiz"
		clear_side_row()
	end
	--clear the checkpoint text
	if word_behaviour=="check" then
		word=""
	end
end

function play_music(num)
	if (current_music!=num) music(num)
	current_music=num
end

function respawn()
	room_x=check_room_x
	room_y=check_room_y
	scroll_dir=check_scroll_dir
	plr.x=60
	plr.y=40
	plr.grav=0
	plr.f=check_flip
	plr.s=0
	cam_x=0
	cam_y=0
	actors={plr}
	hp=max_hp
	clear_top_row()
	rm=load_room(layout[room_y][room_x],0,0,rm_enemies[room_y][room_x],rm_doors[room_y][room_x])
	wipe_transition=131
	wall_pal=check_room_pal
end

function unlock()
	rm_doors[room_y][room_x]=true
end

function update_gate()
	if(gate_counter==nil) gate_counter=0
	if gate_counter>0 then
		gate_counter-=1
		return
	end
	open_gate=false
	local cx=cam_x/8
	local cy=cam_y/8
	for y=cy,cy+16 do
		for x=cx,cx+16 do
			tile=mget(x,y)
			tile2=mget(x,y+1)
			if fget(tile,3) and not fget(tile2,3) then
				if tile==107 then
					mset(x,y,85)
				else
					mset(x,y,107)
				end
				open_gate=true
				gate_counter=5
				sfx(21)
				return
			end
		end
	end
end
-->8
--draw--

function _draw()
	if game_mode=="title" then
		draw_title()
		return
	end
	draw_gui()
	set_room_pal(
		rm_cols[room_y][room_x]
	)
	draw_map()
	--draw_debug()
	--draw_debug_map()
	draw_word()
	draw_hud()
	if (plr.egg)	outline_text("press 🅾️/z!",24,36+sin(sine_timer)*1.5,8)
	if win then
		msg="on the title screen\nenter ⬇️⬇️⬅️⬇️➡️ to\ntry a new challenge"
		if hard_mode then
			msg="  excellent work!\n  you have beaten\n  challenge mode!"
		end
		outline_text(msg,26,40,1)
	end
end

function draw_title()
	cls()
	draw_partics()
	--draw the title
	sin_val=sin(sine_timer)*2-10
	camera(-2,sin_val)
	for i=2,5 do
		spr(i+7,8*i,0)
	end
	for i=1,6 do
		spr(i+22,8*i,8)
	end
	for i=0,7 do
		spr(i+39,8*i,24)
	end
	spr(13,29,16)
	camera()
	if ((sine_timer*2)%1>0.4)	outline_text("press ❎",16,54,1)
	--these label the modes
	--but i don't really like them
	--if (hard_mode)	outline_text("challenge mode",4,35-sin_val,11)
	--if (slow_mode)	outline_text("slow mode",14,35-sin_val,12)
end

function outline_text(str,x,y,c,back_col)
		back_col=back_col or 7
		if back_col!=0 then
  	for i=x-1,x+1 do
  		for j=y-1,y+1 do
  			print(str,i,j,back_col)
  		end
  	end
 	end
 	print(str,x,y,c)
end

function draw_word()
	--if (#word==0) return
	word_timer+=0.25
	if (word_timer>#word)	word_timer=0
	local x=64-#word
	local len=#word/2
	for i=1,len do
		local y=8+v_offset
		local y2=16+v_offset
		if flr(word_timer)==i then
			y+=1
		elseif flr(word_timer)==i-2 then
			y-=1
		end
		if flr(word_timer)==i+len then
			y2+=1
		elseif flr(word_timer)==i-2+len then
			y2-=1
		end
		bc=7
		if (word=="checkpoint") bc=0
		outline_text(sub(word,i,i),x,y,word_col,bc)
		outline_text(sub(word,i+len,i+len),x,y2,word_col,bc)
		x+=4
	end
end

--draw gui elements
function draw_hud()
	draw_hp()
	draw_minimap()
	draw_got_items()
end

function draw_hp()
	local y_pos=72
	for i=0,max_hp-1,2 do
		spr(61,4+i*4,y_pos)
	end
	for i=1,hp do
		if i%2==1 then
			spr(60,i*4,y_pos)
		else
			spr(59,-4+i*4,y_pos)
		end
	end
end

function draw_minimap()
	for i=3,69,3 do
		for j=0,39,3 do
			--draw guide dots.
			pset(55+i,82+j,5)
		end
	end
	for i=0,22 do
		for j=0,13 do
			draw_minimap_room(i,j)
		end
	end
	local plr_x=55+room_x*3+1
	local plr_y=82+room_y*3+1
	if ((sine_timer*2)%1>0.5) rect(plr_x,plr_y,plr_x+1,plr_y+1,11)
end

function draw_minimap_room(x,y)
	local explored=explored_rooms[x][y]
	if (not explored) return
	local room=rooms[layout[y][x]]
	local map_x=55
	local map_y=82
	local x_corner=55+3*x
	local y_corner=82+3*y
	local col=10
	local side_col={}
	for i=0,3 do
		side_col[i]=2
	end
	if (room["save"])	col=12
	if (room["item"])	col=9
	if explored=="verti" then
 	if (room["up"]=="open") side_col[1]=col
 	if (room["down"]=="open") side_col[3]=col
 	if (room["left"]=="open") side_col[2]=8
 	if (room["right"]=="open") side_col[0]=8
	else
		side_col[0]=col
		side_col[2]=col
		if (room["left_stop"]) side_col[2]=8
 		if (room["right_stop"]) side_col[0]=8
		if (room["left"]=="wall") side_col[2]=2
 		if (room["right"]=="wall") side_col[0]=2
	end
	--the centre of the room
	rectfill(x_corner,y_corner,
		x_corner+3,y_corner+3,col)
	--the outside corners
	rect(x_corner,y_corner,
		x_corner+3,y_corner+3,2)
	--top edge
	rectfill(x_corner+1,y_corner,
		x_corner+2,y_corner,
		side_col[1])
	--bottom edge
	rectfill(x_corner+1,y_corner+3,
		x_corner+2,y_corner+3,
		side_col[3])
	--right edge
	rectfill(x_corner+3,y_corner+1,
		x_corner+3,y_corner+2,
		side_col[0])
	--left edge
	rectfill(x_corner,y_corner+1,
		x_corner,y_corner+2,
		side_col[2])
end

function draw_got_items()
	draw_got_item(got_double_jump,85,49,"double jump")
	draw_got_item(got_fireball,95,50,"fireball")
	draw_got_item(got_charge,105,51,"charge")
	--draw_got_item(got_belly_flop,115,52,"belly flop")
	--keys
	spr(53,108,72)
	print(keys,120,73,7)
	--eggs
	for i=1,eggs do
		spr(53+i,49+i*10,71)
	end
end

function draw_got_item(var,y,s,text)
		if (not var) return
		spr(s,3,y)
		print(text,13,y+1,7)
end

function draw_init()
	v_offset=2
	bg_col=0
	--palette info
	wall_pal="grey"
	grass_pal="green"
	stone_pal="grey"
	rm_pals={}
	rm_pals["red"]={2,8,14}
	rm_pals["grey"]={5,6,13}
	rm_pals["green"]={3,11,10}
	rm_pals["blue"]={1,12,13}
	rm_pals["lilac"]={13,6,7}
	rm_pals["lilac2"]={13,7,6}
end

function set_room_pal(p)
	--these are the room palettes
	local pals={}
	--walls, grass, stone
	--pals["1"]={"grey","green","grey"}
	pals["1"]=split_string("grey,green,grey")
	--pals["2"]={"grey","lilac","blue"}
	pals["2"]=split_string("grey,lilac,blue")
	pals["3"]=split_string("lilac,lilac,blue")
	pals["4"]=split_string("lilac,green,grey")
	pals["5"]=split_string("grey,green,lilac2")
	pals["6"]=split_string("blue,green,lilac2")
	pals["7"]=split_string("grey,red,green")
	pals["8"]=split_string("red,red,green")
	pals["9"]=split_string("green,green,grey")
	pals["a"]=split_string("blue,green,grey")
	--get the correct ones
	local palette=pals[p]
	--return if no palette required
	if (palette==nil) return
	--set these palettes
	wall_pal=palette[1]
	grass_pal=palette[2]
	stone_pal=palette[3]
end

function draw_map()
	clip(0,v_offset,128,64)
	camera(cam_x,cam_y-v_offset)
	rectfill(0,0,127,127,bg_col)
	set_map_palette()
	map(0,0,0,0,map_w,map_h)
	pal()
	foreach(actors,draw_actor)
	draw_partics()
	set_map_palette()
	map(0,0,0,0,map_w,map_h,0b00000010)
	draw_wipe()
	pal()
	clip()
	camera()
end

--draw the wipe transition
function draw_wipe()
	if wipe_transition>0 then
		rectfill(128,0,131-wipe_transition,128,0)
	end
end

--draw currently loaded partics
function draw_partics()
	foreach(partics,draw_partic)
end

--draw an actor
function draw_actor(a)
	if a.invul!=nil and a.invul%4>1 then return end
	local y=a.y
	if a.up != nil then
		y-=a.up
	end
	actor_pal(a.pal)
	vf=a.vf
	if (vf==nil) vf=false
	spr(a.s,a.x,y,1,1,a.f,vf)
	pal()
	draw_actor_healthbar(a)
end

function draw_actor_healthbar(a)
	--make sure the actor has health
	if a.hp==nil or a.max_hp==nil then return end
	--don't draw when full.
	if a.hp>=a.max_hp then return end
	--don't draw with no health.
	if a.hp<=0 then return end
	--how full is it?
	size=(a.hp/a.max_hp)*8
	--fill the red bit of the bar
	rectfill(a.x,a.y-4,a.x+size-1,a.y-2,8)
	--draw outside border.
	rect(a.x-1,a.y-4,a.x+8,a.y-2,5)
end

--draw a partic
function draw_partic(p)
	pset(p.x,p.y,p.c)
	--all partics are mirrored on title
	if game_mode=="title" then
		pset(63-p.x,58-p.y,p.c)
	end
end

function set_map_palette()
	set_grass(get_pal(grass_pal))
	set_wall(get_pal(wall_pal))
	set_stone(get_pal(stone_pal))
end

function set_grass(p)
	pal(3,p[1])
	pal(11,p[2])
	pal(10,p[3])
end

function set_wall(p)
	pal(1,p[1])
	pal(12,p[2])
end

function set_stone(p)
	pal(5,p[1])
	pal(6,p[2])
	pal(13,p[3])
end

function get_pal(name)
	return rm_pals[name]
end

function draw_gui()
	--rectfill(0,0,127,127,0)
	cls()
	line(0,v_offset-2,128,v_offset-2,7)
	line(0,v_offset+room_h*8+1,128,v_offset+room_h*8+1,7)
end
-->8

-->8


-->8
--actors--

function update_actors()
	for a in all(actors) do
		local name=a.name
		if name=="killme" then
			a.dead=true
		elseif a.enemy then
			update_enemy(a)
		elseif name=="save" then
			update_save(a)
		elseif name=="item" then
			update_item(a)
		elseif name=="save_recreator" then
			update_save_recreator(a)
		elseif name=="fireball" then
			update_fireball(a)
		else
		end
		if a.dead then
			del(actors,a)
		end
	end
end

--make moving explosion partics
--cx and cy are the centre.
function explode_actor(a,cx,cy,str)
	if cx==nil then
		cx=a.x+3.5
	end
	if cy==nil then
		cy=a.y+3.5
	end
	if str==nil then str=1 end
	rectfill(0,0,7,7,0)
	actor_pal(a.pal)
	spr(a.s,0,0,1,1,a.f)
	pal()
	for x=0,7 do
		for y=0,7 do
			col=pget(x,y)
			if col!=0 then
				p=new_partic(x+a.x,y+a.y,col,24+rnd(16))
				p.xv=(p.x-cx)*str*explode_rnd()
				p.yv=(p.y-cy)*str*explode_rnd()
				p.xa=0
				p.ya=0.1
				add_partic(p)
			end
		end
	end
end

--returns true if they touch
function actors_intersect(a,b)
	if a.x+8<b.x then return false end
	if b.x+8<a.x then return false end
	if a.y+8<b.y then return false end
	if b.y+8<a.y then return false end
	return true
end

--checks exact pixel collisions
function actors_intersect_adv(a,b)
	--must pass simple test first.
	if not actors_intersect(a,b) then return false end
	--scratchpad area
	rectfill(0,0,16,8,0)
	--draw both sprites to screen
	spr(a.s,0,0,1,1,a.f)
	spr(b.s,8,0,1,1,b.f)
	--calculate differences.
	x_dif=b.x-a.x
	y_dif=b.y-a.y
	for x=max(0,x_dif),min(7,7+x_dif) do
		for y=max(0,y_dif),min(7,7+y_dif) do
			a_pix=pget(x,y)
			b_pix=pget(8+x-x_dif,y-y_dif)
			--if two pixels overlap...
			if a_pix!=0 and b_pix!=0 then
				return true
			end
		end
	end
	--no collision
	return false
end

function update_save(a)
	local collide=false
	for b in all(actors) do
		if b.name=="savepart" or b.name=="save" then
			if actors_intersect(b,plr) then
				collide=true
			end
		end
	end
	if collide then
		local cx=a.x+7.5
		local cy=a.y+7.5
		local str=0.4
		for b in all(actors) do
			if b.name=="savepart" or b.name=="save" then
				explode_actor(b,cx,cy,str)
				b.dead=true
			end
		end
		sfx(5)
		word="checkpoint"
		word_col=12
		word_behaviour="check"
 	check_room_x=room_x
 	check_room_y=room_y
 	check_scroll_dir=scroll_dir
 	check_flip=plr.f
 	check_room_pal=wall_pal
 	hp=max_hp
	end
end

function update_item(a)
	if item_move_down>0 then
		a.y+=1
		item_move_down-=1
		play_music(8)
		for i=0,3 do
			a.g[i].y+=1
		end
	end
	if a.timer==0 then
		for i=0,3 do
			--make the glow flicker
			a.g[i].s=95-a.g[i].s
		end
		a.timer=4
	else
		a.timer-=1
	end
	if actors_intersect(a,plr) then
		open_gate=true
		a.dead=true
		for i=0,3 do
			--kill the glowy parts
			a.g[i].dead=true
			a.g[i].s=15
		end
		play_music(1)
		if a.s==48 then
			word="extraheart"
			max_hp+=2
			hp=max_hp
		elseif a.s==49 then
			word="double jump "
			got_double_jump=true
		elseif a.s==50 then
			word="fireball  (❎ )  "
			got_fireball=true
		elseif a.s==51 then
			word="fireball charge "
			got_charge=true
		elseif a.s==52 then
			word="bellyflop!"
			got_belly_flop=true
		elseif a.s==53 then
			word="magic key "
			keys+=1
		else
			word="dragon egg          "
			eggs+=1
			hp=max_hp
			if eggs==4 then
				win=true
				play_music(11)
			end
		end
		word_col=8
		word_behaviour="check"
		item_wait=110
		rm_items[room_y][room_x]=0
	end
end

function new_fireball(x,y,f,big)
	if big==nil then big=false end
	if not big then
		a=new_actor(x+2,y+2,7)
		a.spd=2
		a.w=4
	else
		a=new_actor(x+1,y+1,8)
		a.spd=1.5
		a.w=6
	end
	a.direc=f
	if f then a.x-=4 else a.x+=4 end
	a.big=big
	a.name="fireball"
	return a
end

function update_fireball(a)
	if a.direc then
		a.x-=a.spd
	else
		a.x+=a.spd
	end
	--check what it hits.
	for b in all(actors) do
		if b.name=="block" then
			local x=a.x
			if a.direc then
				a.x-=a.spd
			else
				a.x+=a.spd
			end
			if actors_intersect_adv(a,b) then
				destroy_block(b,a.x+a.w/2,a.y+a.w/2)
				a.dead=true
				sfx(33)
			end
			a.x=x
		elseif b.enemy and actors_intersect_adv(a,b) then
			local damage=1
			if a.big then damage=3 end
			hit_enemy(b,damage,a)
			a.dead=true
		end
	end
	--partic trail
	local x=a.x+rnd(a.w-1)
	local y=a.y+rnd(a.w-1)
	local col=8+rnd(2)
	if a.x+a.w<cam_x or
				a.x-128>cam_x then
		a.dead=true
	end
	if is_solid(a.x,a.y)
	or is_solid(a.x+a.w,a.y)
	or is_solid(a.x,a.y+a.w)
	or is_solid(a.x+a.w,a.y+a.w) then
		a.dead=true
		local cx=a.x
		if not a.direc then
			cx+=a.w
		end
		explode_actor(a,cx,a.y+a.w-1,0.25+rnd(0.5))
	end
	if not a.dead then
		p=new_partic(x,y,col,1+a.w)
		add_partic(p)
	end
end

function destroy_block(a,cx,cy)
	unlock()
	--strength of explosion
	explode_actor(a,cx,cy,0.15)
	a.dead=true
	tilx=a.x/8
	tily=a.y/8
	mset(tilx,tily,mget(tilx-1,tily,0))
	for b in all(actors) do
		if b.name=="block" and not b.dead then
			destroy_block(b,cx,cy)
		end
	end
end

--update all enemies
function update_enemy(a)
	if actors_intersect_adv(a,plr) then
		hit_plr(a,a.damage)
	end
	local name=a.name
	if name=="beetle" then
		update_beetle(a)
	elseif name=="jellyfish" then
		update_jellyfish(a)
	elseif name=="slime" then
		update_slime(a)
	elseif name=="skeleton" then
		update_skeleton(a)
	elseif name=="skull" then
		update_skull(a)
	elseif name=="bat" then
		update_bat(a)
	end
end

--hit an enemy with a fireball
function hit_enemy(a,damage,fb)
	a.hp-=damage
	if a.hp<=0 then
		a.dead=true
		--find the centre for explosion
		local cx=fb.x+fb.w/2
		local cy=fb.y+fb.w/2
		--explode this sprite.
		explode_actor(a,cx,cy,0.2*damage)
		sfx(9)
		num_enemy=0
		for i in all(actors) do
			if i.enemy then
				num_enemy+=1
			end
		end
		if num_enemy<=1 then
			item_move_down=24
		end
	else
		sfx(8)
	end
end

function update_beetle(a)
	if a.timer==nil then a.timer=0 end
	a.timer+=1
	if a.timer>8 then
		a.timer=0
		a.s=33-a.s
		if a.f then
			a.x-=1
		else
			a.x+=1
		end
		if is_in_wall(a)
		or not is_solid(a.x-1,a.y+8)
		or not is_solid(a.x+8,a.y+8) then
			a.f=not a.f
			if a.f then
 			a.x-=1
 		else
 			a.x+=1
 		end
		end
	end
end

function update_slime(a)
	--fall up or down.
	if a.s==22 then
			local fspeed=2^a.lv --fall speed
			if a.vf then
				a.y+=fspeed
			else
				a.y-=fspeed
			end
			if is_solid(a.x+4,a.y) or is_solid(a.x+4,a.y+7) then
				a.y+=fspeed
				if a.vf then
					a.y-=2*fspeed
				end
				a.vf=not a.vf
				a.s=20
			end
		return
	end
	if a.timer==nil then a.timer=0 end
	a.timer+=1
	if a.timer>6-a.lv then
		local d=a.x>plr.x
		a.timer=0
		a.s=41-a.s
		if d then
			a.x-=1
		else
			a.x+=1
		end
		if is_in_wall(a) then
			if d then
 			a.x+=1
 		else
 			a.x-=1
 		end
		end
		--fall on the player
		if a.vf and abs(plr.x-a.x)<16 then
			a.s=22
		elseif not a.vf and abs(plr.x-a.x)<8 and a.lv>1 then
			a.s=22
		else
			addition=8
			if (a.vf) addition=-1
 		if not is_solid(a.x-1,a.y+addition)
 			or not is_solid(a.x+8,a.y+addition) then
 			a.s=22
 		end
		end
	end
end

function update_jellyfish(a)
	if a.state=="wait" then
		if abs(a.x-plr.x)<32-6*a.lv then
			a.state="hop"
		end
		a.anim+=1
		if a.anim==10 then
			a.y+=1
		elseif a.anim>=20 then
			a.y-=1
			a.anim=0
		end
	elseif a.state=="hop" then
		a.y-=4
		a.s=19
		if a.y<=a.hop then
			a.state="float"
			a.anim=0
		end
	else
		a.anim+=1
		if a.anim==10-2*a.lv then
			a.s=18
			a.y+=1
		elseif a.anim>=20-4*a.lv then
			a.s=19
			a.anim=0
			a.y+=1
		end
		if a.y>=53 then
			a.y=53
			a.anim=0
			a.state="wait"
		end
	end
end

function update_skeleton(a)
	a.hp=min(a.hp,a.skull.hp)
	a.skull.hp=a.hp
	a.skull.damage=a.damage
	a.skull.pal=a.pal
	xdif=a.x-plr.x
	max_s=0.15*(a.lv+3)
	if xdif>0 then
		a.mom=max(-max_s,a.mom-0.1)
	else
		a.mom=min(max_s,a.mom+0.1)
	end
	if abs(xdif)>72 then
		a.mom=0
	end
	update_mom(a)
	gravity(a)
	a.skull.f=xdif>0
	a.f=a.mom<=0
	a.skull.x=a.x
	a.skull.y=a.y-5-a.up
	animate_walk(a,35,3)
 --jump code
 local fbdif=64
 local plrdif=64
 for b in all(actors) do
 	if(b.name=="fireball")	fbdif=min(fbdif,abs(b.x-a.x-2))
 	if(b.name=="plr")	plrdif=min(plrdif,abs(b.x-a.x))
 end
	if is_on_ground(a) and (fbdif<12 or plrdif<4) then
		a.grav=-3-a.lv/2
		sfx(3)
	end
	if (a.skull.dead) a.dead=true
end

function update_bat(a)
	if to_lock_room then
		boss_gate_timer=24
		to_lock_room=false
	end
	a.s=74+(a.sine_timer*12)%3
	if a.pause>0 then
		a.pause-=1
		a.pal=nil
		if (a.pause%4<2)	a.pal="flash"
		return
	end
	a.x+=(a.goal_x-a.x)/8
	a.y+=(a.goal_y-a.y)/8
	a.sine_timer+=0.01*a.lv
	if rnd(100)<1 then
		a.sine_timer+=0.5
		a.pause=30
		return
	end
	if (a.sine_timer>=1) a.sine_timer-=1
	a.goal_x=plr.x+sin(a.sine_timer)*a.len
	a.goal_y=plr.y+cos(a.sine_timer)*a.len
end

function update_skull(a)
	if (a.body.dead)	gravity(a)
end

function animate_walk(a,s)
	if (rate==nil) rate=1
	a.anim+=abs(a.mom)*rate
	if a.mom==0 then
		a.anim=0.9
		a.s=s
	end
	if a.anim<5 then
		a.up=a.s-s
	else
		a.up=1+a.s-s
	end
	if a.anim>8 then
		a.anim=0
		a.s=s*2+1-a.s
	end
end

function actor_pal(name)
	if name==nil then return end
	if name=="flash" then
		pal(11,7)
		pal(3,6)
		pal(8,9)
	elseif name=="red" then
		pal(11,14)
		pal(3,8)
		pal(8,9)
	elseif name=="blue" then
		pal(11,13)
		pal(3,1)
		pal(1,2)
	elseif name=="white" then
		pal(11,7)
		pal(3,6)
		pal(1,5)
	end
end
-->8
--player functions--

function update_plr()
	--as an egg
	if plr.egg then
		if btnp(4) then
			explode_actor(plr)
			plr.egg=false
			play_music(2)
		end
		return
	end
	--check for gates
	local rm_i=rm_items[room_y][room_x]
	if (is_gate(plr.x+12,plr.y)
		or is_gate(plr.x-4,plr.y)) then
 	if keys>0	and rm_i == "/" then
 		keys-=1
 		open_gate=true
 		unlock()
 	elseif eggs>=3	and rm_i == "!" then
 		open_gate=true
 		unlock()
 	end
	end
	if hp<=0 then return end
	if plr.invul==nil then
		plr.invul=0
	else
		if plr.invul>0 then
			plr.invul-=1
		end
	end
	plr.prev_x=plr.x
	mom_by_arrows(plr)
	update_mom(plr)
	gravity(plr)
	if btn(4) then
		if jump_pushed==nil then
			jump_pushed=true
 		if is_on_ground(plr) then
 			plr.grav=-4
 			sfx(3)
 		elseif got_double_jump and
 									plr.spin==-1 then
 			plr.grav=-3
 			plr.spin=0
 			sfx(4)
 		end
 	end
	else
		jump_pushed=nil
	end

	--check for fireballs
	shoot_fireballs()

	if is_on_ground(plr) then
		plr.spin=-1
	end

	anim_plr()

	--transition on screen edge
	if plr.x<cam_x-4 then
		tr_start("left")
	elseif plr.x>cam_x+124 then
		tr_start("right")
	end

	if is_lava(plr.x+4,plr.y+8) then
		hit_plr(plr,2)
		plr.grav=-5
	end
end

function shoot_fireballs()
	if (not got_fireball) return
	if btn(5) then
		fireball_timer+=1
		if got_charge and fireball_timer==charge_time then
			sfx(7)
		end
	else
		if fireball_timer>0 then
			if got_charge and fireball_timer>=charge_time then
				a=new_fireball(plr.x,plr.y,plr.f,true)
				sfx(1)
			else
				a=new_fireball(plr.x,plr.y,plr.f)
				sfx(0)
			end
			add_actor(a)
		end
		fireball_timer=0
	end
end

function anim_plr()
	if plr.mom>0 then
		plr.f=false
	elseif plr.mom<0 then
		plr.f=true
	end
	if not is_on_ground(plr) then
		plr.s=1
		if plr.spin!=-1 then
			plr.s=plr.spin+2
			plr.spin+=0.25
			local p=new_partic(plr.x+1+rnd(6),plr.y+1+rnd(6),11,5+rnd(3))
			local p=new_partic(plr.x+1+rnd(6),plr.y+1+rnd(6),10,5+rnd(3))
			add_partic(p)
			if plr.spin>=4 then
				plr.spin=0
			end
		end
	else
		if plr.s>1 then
			plr.s=0
		end
 	animate_walk(plr,0)
	end
	if fireball_timer>=charge_time and got_charge then
		plr.pal=nil
		if (fireball_timer%4<2)	plr.pal="flash"
	else
		plr.pal=nil
	end
end

function hit_plr(a,damage)
	if plr.invul==0 then
		hp-=damage
		plr.invul=60
		sfx(10)
		--fly off when hit! pew!
		if plr.x<a.x then
			plr.fly=-10
		else
			plr.fly=10
		end
		if is_on_ground(plr) then
			plr.grav=-2
		end
		if hp<=0 then
			respawn_timer=120
			plr.fly=0
			plr.invul=0
			plr.grav=0
			explode_actor(plr)
			plr.s=15
			play_music(-1)
			sfx(18)
			deaths+=1
		end
	end
end
__gfx__
00303000003030000003330000bb330003b8b0000033bb30222022200880000008888000d770000000d7700d7700d770000000000000d7700002000800000000
000bbbb0000bbbb003333330000bbb303b8b00000333bbb3202020008998000089999800d770000d77d7700d7700d770000000000d70d7700000200800000000
003b8b8b003b8b8b3bbb3333000bbb30bbbbb00b333bbb8b220022008a78000089999800d770000000d7777d7777d77000d77770d77777002222220800000000
03bbbbbb03bbbbbb3bbbbb33b0bbbb33bbb3bbbb333b3bb820202000088000008999a800d77000d777d7700d7700d7700d770d770d7000000000200800000000
03bbbb0003bbbb00bbbb3bbb8bb3b33333bbbbb333bbbb0b222020220000000089aa7800d770000d77d7700d7700d7700d777777000000000002000800000000
3bb3bb003b3bbb00b00bbbbbb8bbb3333333bbb303bbb000000000020000000008888000d777777d77d7700d7700d7700d770000000000002200222800000000
3bbbbb00bbbbbbbb0000b8b33bbb33300333333003bbb000000000000000000000000000d777777d770d7770d7770d7770d77770000000002020202800000000
0bb00bb00b0000b0000b8b3003bb3300003330000033bb0000000020000000000000000000000000000000000000000000000000000000002020222800000000
00000000000000000033300000333000000000000000000000033000d77777000000000000000000000000000000000000000000004444444444442000000000
00bbbb0000bbbb000377b3000377b30000000000000330000037b300d770d7700000000000000000000000000000000000000000004422244422442000089000
0b3333300b33333037bbbb3037bbbb30003333000037b300037bbb30d770d77d77d770d7777700d777770d77770d777770000000000444244422444200888900
b3333003b33330033bbbbb303bbbbb300377bb30037bbb3003bbbb30d770d77d77700d770d770d770d77d770d77d770d77000000000442244222244208888890
33330bb033330bb0060606000606060037bbbbb303bbbb3003bbbb30d770d77d77000d770d770d770d77d770d77d770d77000000000444244222244200000000
3330bbbb3330bbbb06060600060606003bbbbbb303bbbb3003bbbb30d770d77d77000d770d770d770d77d770d77d770d77000000004422244422442088888888
b3b0b1b1b3b0b1b160060060060606003bbbbbb303bbbb30003bb300d777770d770000d777d770d777770d77770d770d77000000004444444444442000000000
00b0bbbbb000bbbb00000000000600000333333000333300000330000000000000000000000000000d7700000000000000000000000000044420000000000000
00d6660060d666000000000000000000000000000000002200033000002eee0000000ee0000000000000000000002ee000000000000000000000000000000000
6d6666006d666600000000000000000000000000000022dd003b7300002eee0000000ee0000000000000000000002ee000000000000000000000000000000000
6d6555006d6555000000000000300300003003000002dd7703bbb73002ee2ee002eeeee2ee02ee02eeee02eeeee02eeee2ee02ee2ee2ee2eeee0000088888888
6d665bbb6d665bbb006777000333330003333300002d777703bbb73002ee2ee02ee02ee2ee02ee2ee02ee2ee02ee2ee002ee02ee2eee02ee02ee000000000000
60365bbbb0365bbb06777770033333300733333702d777773bbbbbb302eeeee02ee02ee2ee02ee2eeeeee2ee02ee2ee002ee02ee2ee002eeeeee000008888890
b3333bbb03333bbb0677b7b0037333370333333002d777773bbbbbb32ee002ee2ee02ee02eeee02ee00002ee02ee2ee002ee02ee2ee002ee0000000000888900
033333bb033333bb0677777005500550750000572d77777703bbbb302ee002ee02eeeee002ee0002eeee02ee02ee02eee02eeeee2ee0002eeee0000000089000
55000550005555000006707007770777077000702d77777700333300000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ccc99900080000009900a000c99c000aa0000000011000000220000009900000000000000000000220220002202200022022000000000000000000
022022500c11119900088000aa0990a00c1991c0aaaa0000001c710000287200009a790000000000000000222882882028826620266266200006000000006000
28828825c19919190088880000a99a09c119911ca99aaaaa01ccc7100288872009aaa79000000000000022dd2888882028886620266666200066000000006600
28a8a825c911911c0089980009988999c119911ca00aaaaa01ccc7100288872009aaa790000000000002dd772888882028866620266666200666000000006660
28aaa825c911911c089aa98099988990c999999caaaa9a9a1cccccc1288888829aaaaaa900000000002d77770288820002886200026662000566000000006650
028a82509111111c089aa98090a99a00c199991c9aa909091cccccc1288888829aaaaaa900000000002d77770028200000262000002620000056000000006500
002825009c1111c0008998000a0990aa0c1991c00990000001cccc100288882009aaaa900000000002d777770002000000020000000200000005000000005000
0002500090cccc00000880000a00990000cccc00000000000011110000222200009999000000000002d777770000000000000000000000000000000000000000
0003333333333333333333000ccccc000ccccccccccccc00011100000000000000000000000000000000000000000000000000000000000c0000000009999990
003ba3b3b33ba3b3b33ba3b0cc1c11c0cc1c11c1111c11c010000000000000000000000000000000050000500500005005000050000000cc700000009aaaaaa4
0ba5bb0a5ba5bb0a5ba5bb65c1111110c1111111111111101000000000000000000000000000000000555500005555006055550600000c1cc70000009aaaaaa4
6db50b0506b50b0506b50bd5c1111110c111111111111110000000000000000000000000000000000635536066355366563553650000c11c7c7000009a9aa9a4
65006d506d006d506d006d50c1111110c11111111111111011100000111001111110000000000111655555565555555505555550000c111cc7c700009a9aa9a4
d550d550d550d550d550d550c1110110c1110111111101100000000000001000000000000000100055055055500550050005500000c0c1c17c7c70009aaaaaa4
5550550055505500555055000110110001101110111011000000000000001000000000000000100050000005000000000000000000c10c1117c170009aaaaaa4
0550506d0550506d0550506d0000000000000000000000000000000000000000000000000000000000000000000000000000000000c01c11171c700004444440
000606d5500606d550060600000000000000000001111110000001101101100101010010a00aa00a07777770077777700777777000c10c1117c1700000000000
006d5055506d5055506d5550000000000000000010000000000010000001100001001010aaaaaaaa07900980079999800790098000c01c111c1c700000000000
06d5500550d5500550d550650000000000000000100000000000100001011011010100109aa99aa907900980079999800700008000c0c0c1c1c1700000000000
6d05060506050605060506d500000000000a00000000000000000000000110000100101099999999070000800888888007000080000c010c111c000000000000
65006d506d006d506d006d55000000000000000011100111000001111101100101010010999999990700008007777770079009800000c01c11c0000000000000
d550d550d550d550d550d5550000000000000000000010000000100000011000010010109999999907000080079999800700008000000c0c1c00000000000000
5550550055505500555055000b0b00b0000000000000100000001000010110110101001088999988079009800799998007999980000000ccc000000000000000
0550506d0550506d0550506d33b3033b0000000000000000000000000001100001001010888888880888888008888880088888800000000c0000000000000000
006606d5500606d5500606d00000000005000000cccccccc0000000000000000333333334a444a44003000300777777089999998099999999999999000000000
06d55055506d5055506d50500000000050000000111c11c10000000000000000b33ba3b3595559550030003007999980899999889aaaaaaaaaaaaaa400000000
0d55500550d5500550d5500000033000500000001111111100000000000000005ba5bb0a90999099003003b007999980889988889aaaaaaaaaaaaaa400000000
005506050605060506055500003003000000000011111111000000000000000006b30b050000000000a3030008888880088888809aaaaaaaaaaaaaa400000000
00006d506d006d506d05550000000300000000001111111100000000000077706d303d50000000000030300011100111000000009aaaaaaaaaaaaaa400000000
0000d550d550d550d55050000000030000000000111101110880000000077777d530b350000000000030b30000001000000000009aaaaaaaaaaaaaa400000000
000055505550555055500000000030000000000011101110888800000005757753b053000000000003b0030000001000000000009aaaa9aaaa9aaaa400000000
00000500550005005500000000030000000000000000000007700000000757760350536d000000000300030000000000000000009aaaa9aaaa9aaaa400000000
000606d550060000000000000000000000050550500606d550333333333336d550360635503606350300030051ccccccccc111559aaaa9aaaa9aaaa488888888
006d5055506d5000000000000000000000065550506d5055506ba3b3b33b5055503d5035503d503503000300c551ccccc11115559aaaa9aaaa9aaaa488888888
06d5500550d5500000000000000000000006d55050d5500550d5bb0a5ba55005503553b5503553b503003b00ccc55111111555519aaaaaaaaaaaaaa488888888
0555060506055500000000000000000000006d000605060506050b0506b5060506a3030506a303050a3030001cccc555555551159aaaaaaaaaaaaaa488888888
00506d506d055500600000000000000000006d006d006d506d006d506d006d506d303d506d003d500003000051ccccccccc111559aaaaaaaaaaaaaa488888888
0000d550d55050006d0000000000000000000600d550d550d550d550d550d550d530b350d550d550000000000551ccccc11115559aaaaaaaaaaaaaa488888888
0000555055500000d5000000000000060000060055505500555055005550550053b05300555055000000000000055111111555509aaaaaaaaaaaaaa488888888
0000050055000000055000000000006d000000000550506d0550506d0550506d0350536d0550506d000000000000055555555000044444444444444088888888
5444544454445444f1445444544454445444544454445444f1445444544454445444544454445444f14454445444544415260000000000000000000000000615
15150000000000000000000000000615151500000000000000000000000015151515151515151515f11515445444544454345585000000030000f10085553444
44544454000044565654000044544454445444544454445444544454445444544454445444544454445444544454445415000000000000000000000000000015
15260000000000000000000000003715151500000000000000000000000015151515151616161516161615164454445444545585000000000000000085554454
54445485000085555585000085445444544454850085555555558500855555555555558500855555555585008544544415270000000000000066000000003715
1500000000000000000000000037051554150000000001000000000000001544151516460000470000004700004454445434558500b4000000c4000085553444
44545585000085555585000085554454445455850085555555558500855555555555558500855555555585008555445415250000000716161616170000004454
26000000000000370515151544544454445400000007161616161700000044541616460000000000000000000000445444545585000000a40000000085554454
55555585000085555585000085555555555555850085555555558500855555555555558500855555555585008555555515260000000000000000000000006555
00000000000000051515151515445444556400000000000000000000000065550000000000000000000000000000655555555585000000000000000085553444
e35555850000855555850000855555f3e3555585008555555555850085555555555555850085555555558500855555f3150000000000000000000000000065f3
e3000000000037678614141444544454e35500000000000000000000000055f300000000000000000000000000006555e35555850000000000000000855544f3
55555585000085552285000085555555555555850085555522558500855555555555558500855522555585008555555515270000000000000000000000766555
00000000003705158715154454445444555564000000000000110000006555550035760000000000000000000066655555555585000000000000000085553444
4454445444544454f2544454445444544454445444544454f2544454445444544454445444544454f25444544454445415151517000000000000000007154454
15151515f2151515871544544454445444544454151515151515f21544544454671477170000000000000000071615344454445444544454f254445444544454
15151515152600000000000000000000000000445444544454445444544454445444544454445444f14454445444544454000000000000000000000000003444
5444540000000000000000000000061554445444549715f11587151515151515544454445444544454151515151515155444544454445444544454445415f115
15151626470000000000000000000000000000344454445444544454445444544454445444544454445444544454445444540000000000000000000000004454
44543400000000000000000000000015445444540715151516871615151515154454445444544454161526061515151544544454445444544454445434151515
15260000000000000000000000000000000000445444540085555585004454445555558500855555555585008555555554445400000000000000000000445444
54445400000066000000000000000015544454000047062600a70047061515155555558500445400004700000616151554445400855555850044544454061615
26000000000000000000000000000000000000445654850085555585008544545555558500855555555585008555555544544454445400000000000000344454
44543400000716170000000000003715445400000000000000000000000615155555558500856400000000000000061644548500855555850085445654000006
0000000000000000000000000000000000000065b555850085555585008555555555558500855555555585008555555555555544545500000000000000655555
5444540000000000000000000000051555640000000000000000000000001515555555850085640000000000000000005555850085555585008555b564000000
e300000000000000000000000000000000000065c555850085555585008555f355555585008555555555850085555555e35555855564000000000000945555f3
4454000000000000000000000000153455640000000000000000000000001515555555850085550000000000000000f3e355850085555585008555c5640000f3
0066003536000035360066003536350000353565b555850085555585008555555555558500855555225585008555555555555585555555748422945555555555
5400000000000000000000000000154455640000000000000000000000001515555555850085556400000035353600005555850085555585008555b564003536
15156714776714141414141414141414141414445654445444544454445444544454445444544454f254445444544454445444544454f2544454445444544454
3400000000000000000716170000445444544454000000000000000000001515445444544454445415156714141477154454445444f244544454445654671477
54445444544454161687161615158715543415158715151587161515f1151515161687161616161616161616161616161515150006260006260006260015f115
544454850085555555558500854454445444548500855555555585008544544454445444544454f1544454445444544454445444544454f15444544454445444
445444544454000000a60000061587154454151587151526a6510615151567860000a600000000000000000000a6000015152600000000000000000000061515
44545585008555555555850085554454445455850085555555558500855544544454445444544454445444544454445444544454445444544454445444544454
555555b55564000000a70000000687155434161687260000a6000015678677870000a700000000000000000000a6000015260000000000000000000000000615
54345585008555555555850085553444543455850085552255558500855534445444544454445444544454445444544454445444544454445444544454445444
555555a555000000000000000000a70644540000a7000000a60000061587158700000000000041353536000000a6000026000000000000000000000000000006
44545585004456565656540085554454445455850044565656565400855544544454558500855555555585008555445444545585008555555555850085554454
555555a56400000000000000000000005564000000000000a60000001587158700000000000414148614240000a7000000000000000000361100000000000000
55555585008555555555850085553444543455850085555555558500855534445434558500855555555585008555555555555585008555555555850085553444
555555a56400000000d1e100000000f3e364000000000000a70000000697158700000000000615158715260000000000e30000001137041414242701000000f3
e35555850085555555558500855544f3e35455850085555555558500855544f3e35455850085555555558500855555f3e35555850085555555558500855544f3
555555b5558400000414142400000000556400000000000000000000001515970035353611371515871527016600760000003637041414141414142427360000
55555585008555555555852285553444543455850085555555558500855534445434558500855555555585008555555555555585008555555555850085553444
44544454445467148677156786771515341616170000000000000000000616166714141477151515871515151515151515f26714141414141414141414771515
44565656565455555555445656565654445656565654555555554456565656544456565656545555555544565656565444565656565455555555445656565654
15151515151516151616260000000006152600000000000000000000001515155434558500855555555585008555344454445485008555555555850085445444
54445485008555555555850085445444544400000000000000000000000015155444548500855555555585008544544454445485008555555555850085445444
15151515152600470000000000000000150000000000000000000000001515154454558500855555555585008555445444545585008555555555850085554454
44545585008555555555850085554454445484000000000000000000000015154454558500855555555585008555445444545585008555555555850085554454
15151515260000000000000000000000150000000066010066000000000615155434558500855555555585008555344454345585008555555555850085553444
54345585008555555555850085553444543455850000000000000000000015155434558500855555555585008555344454345585008555555555850085553444
16260626000000000000000021000000152700000616151616161700000006164454558500855555555585008555445444545585004456565656540085554454
44545585004456565656540085554454445455850000000716161700000015154454558500445656565654008555445444545585004456565656540085554454
00000000000000000000000000000000152500000000470000000000000000005434558500855555555585008555344455555585008555555555850085555555
54345585008555555555850085555555543455850000948400000000000015155434558500855555555585008555555555555585008555555555850085553444
e3000000000000000066000000000000151527000000000000000000000000f3e35455850085555555558500855544f3e35555850085555555558500855555f3
e35455850085555555558500855555f3e35425850085555555840000003715f3e35455850085555555558500855555f3e35555850085555555558500855544f3
00372700003600370515960000009696151525270011353536663500000000005434558500855555555585008555344455555585008555225555850085555555
54345585228555555555850085555555543415252785555555558500370515265434558500855522555585008555555555555585008555552255850085553444
1515156714147715151595959595959515151515f26714141414147715151515445455850085555555558500855544544454445444544454f254445444544454
44565656565455555555445656565654445656565654555555558500071626344454445444544454f2544454445444544454445444544454f254445444544454
__label__
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666600066666666666660006666666666666000505005000000000000000000000000000000000050500500666666666666600066666666666660006666666
55565560665655655556556066565565555655600500505000000000000000000000000000000000050050506656556555565560665655655556556066565565
55555550655555555555555065555555555555500505005000000000000000000000000000000000050500506555555555555550655555555555555065555555
55555550655555555555555065555555555555500500505000000000000000000000000000000000050050506555555555555550655555555555555065555555
55555550655555555555555065555555555555500505005000000000000000000000000000000000050500506555555555555550655555555555555065555555
55550550655505555555055065550555555505500500505000000000000000000000000000000000050050506555055555550550655505555555055065550555
55505500055055505550550005505550555055000505005000000000000000000000000000000000050500500550555055505500055055505550550005505550
00000000000000000000000000000000000000000500505000000000000000000000000000000000050050500000000000000000000000000000000000000000
06666666666666000666666666666600055555500505005000000000000000000000000000000000050500500555555006666666666666000666666666666600
66565565555655606656556555565560500000000500505000000000000000000000000000000000050050505000000066565565555655606656556555565560
65555555555555506555555555555550500000000505005000000000000000000000000000000000050500505000000065555555555555506555555555555550
65555555555555506555555555555550000000000500505000000000000000000000000000000000050050500000000065555555555555506555555555555550
65555555555555506555555555555550555005550505005000000000000000000000000000000000050500505550055565555555555555506555555555555550
65550555555505506555055555550550000050000500505000000000000000000000000000000000050050500000500065550555555505506555055555550550
05505550555055000550555055505500000050000505005000000000000000000000000000000000050500500000500005505550555055000550555055505500
00000000000000000000000000000000000000000500505000000000000000000000000000000000050050500000000000000000000000000000000000000000
666666000666666666666600055555500555555005050050000000000000000c0000000000000000050500500555555005555550066666666666660006666666
55565560665655655556556050000000500000000500505000000000000000cc7000000000000000050050505000000050000000665655655556556066565565
5555555065555555555555505000000050000000050500500000000000000c1cc700000000000000050500505000000050000000655555555555555065555555
555555506555555555555550000000000000000005005050000000000000c11c7c70000000000000050050500000000000000000655555555555555065555555
55555550655555555555555055500555555005550505005000000000000c111cc7c7000000000000050500505550055555500555655555555555555065555555
5555055065550555555505500000500000005000050050500000000000c0c1c17c7c700000000000050050500000500000005000655505555555055065550555
5550550005505550555055000000500000005000050500500000000000c10c1117c1700000000000050500500000500000005000055055505550550005505550
0000000000000000000000000000000000000000050050500000000000c01c11171c700000000000050050500000000000000000000000000000000000000000
0666666666666600055555500555555005555550050500500000000000c10c1117c1700000000000050500500555555005555550055555500666666666666600
6656556555565560500000005000000050000000050050500000000000c01c111c1c700000000000050050505000000050000000500000006656556555565560
6555555555555550500000005000000050000000050500500000000000c0c0c1c1c1700000000000050500505000000050000000500000006555555555555550
65555555555555500000000000000000000000000500505000000000000c010c111c000000000000050050500000000000000000000000006555555555555550
655555555555555055500555555005555550055505050050000000000000c01c11c0000000000000050500505550055555500555555005556555555555555550
6555055555550550000050000000500000005000050050500000000000000c0c1c00000000000000050050500000500000005000000050006555055555550550
05505550555055000000500000005000000050000505005000000000000000ccc000000000000000050500500000500000005000000050000550555055505500
000000000000000000000000000000000000000005005050000000000000000c0000000000000000050050500000000000000000000000000000000000000000
05555550055555500555555005555550055555500505005000000000000000000000000000000000050500500555555005555550055555500555555005555550
50000000500000005000000050000000500000000500505000000000000000000000000000000000050050505000000050000000500000005000000050000000
50000000500000005000000050000000500000000505005000000000000000000000000000000000050500505000000050000000500000005000000050000000
00000000000000000000000000000000000000000500505000000000000000000000000000000000050050500000000000000000000000000000000000000000
55500555555005555550055555500555555005550505005000000000000000000000000000000000050500505550055555500555555005555550055555500555
00005000000050000000500000005000000050000500505000000000000000000000000000000000050050500000500000005000000050000000500000005000
00005000000050000000500000005000000050000505005000000000000000000000000000000000050500500000500000005000000050000000500000005000
00000000000000000000000000000000000000000500505000000000000000000000000000000000050050500000000000000000000000000000000000000000
05555550055555500555555005555550055555500505005000000000000000000000000003030000050500500555555005555550055555500555555005555550
50000000500000005000000050000000500000000500505000000000000000000000000bbbb00000050050505000000050000000500000005000000050000000
5000000050000000500000005000000050000000050500500000000000000000000000b8b8b30000050500505000000050000000500000005000000050000000
0000000000000000000000000000000000000000050050500000000000000000000000bbbbbb3000050050500000000000000000000000000000000000000000
555005555550055555500555555005555550055505050050000000000000000000000000bbbb3000050500505550055555500555555005555550055555500555
000050000000500000005000000050000000500005005050000000000000000000000000bb3bb300050050500000500000005000000050000000500000005000
000050000000500000005000000050000000500005050050000000000000000000000000bbbbb300050500500000500000005000000050000000500000005000
00000000000000000000000000000000000000000500505000000000000000000000000bb00bb000050050500000000000000000000000000000000000000000
05555550055555500555555005555550055555500666666666666666666666666666666666666666666666000555555005555550055555500555555005555550
50000000500000005000000050000000500000006656556555565565555655655556556555565565555655605000000050000000500000005000000050000000
50000000500000005000000050000000500000006555555555555555555555555555555555555555555555505000000050000000500000005000000050000000
00000000000000000000000000000000000000006555555555555555555555555555555555555555555555500000000000000000000000000000000000000000
55500555555005555550055555500555555005556555555555555555555555555555555555555555555555505550055555500555555005555550055555500555
00005000000050000000500000005000000050006555055555550555555505555555055555550555555505500000500000005000000050000000500000005000
00005000000050000000500000005000000050000550555055505550555055505550555055505550555055000000500000005000000050000000500000005000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666666666666000666666666666600066666666666660006666666666666000666666666666600066666666666660006666666666666000666666666666600
66565565555655606656556555565560665655655556556066565565555655606656556555565560665655655556556066565565555655606656556555565560
65555555555555506555555555555550655555555555555065555555555555506555555555555550655555555555555065555555555555506555555555555550
65555555555555506555555555555550655555555555555065555555555555506555555555555550655555555555555065555555555555506555555555555550
65555555555555506555555555555550655555555555555065555555555555506555555555555550655555555555555065555555555555506555555555555550
65550555555505506555055555550550655505555555055065550555555505506555055555550550655505555555055065550555555505506555055555550550
05505550555055000550555055505500055055505550550005505550555055000550555055505500055055505550550005505550555055000550555055505500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000022022000220220002202200000000000000000000000000000000000000000000000000000000000000000000000000000000000aa00000000000000000
000028828820288288202882882000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa0000000077700000
000028888820288888202888882000000000000000000000000000000000000000000000000000000000000000000000000000000000a99aaaaa000070700000
000028888820288888202888882000000000000000000000000000000000000000000000000000000000000000000000000000000000a00aaaaa000070700000
000002888200028882000288820000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa9a9a000070700000
0000002820000028200000282000000000000000000000000000000000000000000000000000000000000000000000000000000000009aa90909000077700000
00000002000000020000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000009900000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005005005005005005005005005005005005005005005005005005005005005005005000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ccc999000000000000000000000000000000000000000000000005005005005005005005005005005005005005005005005005005005005005005005000
0000c111199007700077070707770700077700000777070707770777000000000000000000000000000000000000000000000000000000000000000000000000
000c1991919007070707070707070700070000000070070707770707000000000000000000000000000000000000000000000000000000000000000000000000
000c911911c007070707070707700700077000000070070707070777005005005005005005005005005005005005005005005005005005005005005005005000
000c911911c007070707070707070700070000000070070707070700000000000000000000000000000000000000000000000000000000000000000000000000
0009111111c007770770007707770777077700000770007707070700000000000000000000000000000000000000000000000000000000000000000000000000
0009c1111c0000000000000000000000000000000000000000000000005005005005005005005005005005005005005005005005005005005005005005005000
00090cccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005005005005005005005005005005005005005005005005005005005005005005005000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005005005005005005005005005005005005005005005005005005005005005005005000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005005002222222222aa2005005005005005005005005005005005005005005005005000
00000000000000000000000000000000000000000000000000000000000000008bb8aaaaa8aa2000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000008bb8aaaaa8aa2000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005005002222222222aa2005005005005005005005005005005005005005005005005000
00000000000000000000000000000000000000000000000000000000000000000000000002aa2000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000002aa2000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005002222222222222aa2222222222005005005005005005005005005005005005005000
00000000000000000000000000000000000000000000000000000000000002aa8aaaaaaaa8aa8aaaaa8992000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000002aa8aaaaaaaa8aa8aaaaa8992000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005002222222222222222222222222005005005005005005005005005005005005005000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005005005005005005005005005005005005005005005005005005005005005005005000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005005005005005005005005005005005005005005005005005005005005005005005000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005005005005005005005005005005005005005005005005005005005005005005005000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005005005005005005005005005005005005005005005005005005005005005005005000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010100000000000000000081010101020000000000070909090000000101010200010202010302090081810001010202020201010101020000818100
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
444544454445444544454445444544455151516161615161611f516151515151515151615151515151616151515151616161615151615161616151616161616161615151515161615161515151515151516200000000000000000000000060516161615151515151515151615144454445441f55555800000000585555444544
4355515155555151515551555555554351516200000074000000740060515151515162007460515162000060516162000000006062007400000074000000000000007460515100007400746061515151510000000000000000000000000000510000006061616161616274006043444544454355555800000000585555434445
4355515551555551555551555555554351510000000000000000000000605151516200000000606200000000740000000000000000000000000000000000000000000000606200000000000000605151510000000000006353530000000000510000000000000000000000000044454445444555555800000000585555444544
4355515551555551555551555555554351620000000000000000000000006061620000000000000000000000000000000000000000000000000000737200000000000000000000000000000000006061620000000070764141684200000000600000000000000000000000000000444544454355555800300000585555434445
435551555155555155555155555555435100000000000000000000000000000000000000000000000000000000000000000000000000000063000050520000000000000000000000000000000000000000000000735052505178510000000000000000000000000000000000000056555555555555580000000058555544453f
43555155515551515155515151555543517200000000535300000000000000003e000000000000000000000000000000000000737200004042000051510000000000000000000000000000000000003f3e00007350416877517951000000003f0000000000001053637372000000563f3e555555555800000000585555434445
4355555555555555555555555555554351527273404141414142727372000000000000007372000073505272737210000000735052727351517273515172000000000073721073720053537372000000000073407751785176417772535363000000000073507641417752720000565555555555554465656565455555444544
4445444544454445444544454445444551515151515151515151512f51515151515151515151515151515151515151515151515151515151515151515151515151515151515151517641417751515151515151515151795151512f76414141775151515151515151515151515151444544454445444544454445442f44454445
45444544455800001f00584445444544516200000000000000000000000051515162000000000000000000000051514445435161616161616161616161786161616161616151616178615161615151515162000000000000000000000000605151510000000000000000000000006051454445551f5800000000585555444544
444544455558000000005855444544455100000000000000000000000000515151000000000000000000000000514445444551640000000000000000006a000000000000007400006a00740000745151510000000000000000000000000000515162000000000000000000000000005144454355555800000000585555434445
454445555558004d00005855554445445100000000000066006300000000515151000000006610006600000000604344454351720000000000000000006a000000000000000000007a00000000006051510000000000000053630000000000515100000000000063530000000000005145444555555800000000585555444544
444555555558000000005855555544455100000000707641417771000000605151720000606151616161710000004445444561620000607641775200007a000000000000000000000000000000000060510000000070517641777100000000516200000000707668417771000000005144454355555800300000585555434445
555555555558000000005855555555555100000000000000000000000000005151520000000074000000000000005655554600000000005151515172000000000000000000001053630000000000000051720000000000000000000000000051000000000000007a740000000000405155555555555800000000585555555555
3e55555555580000000058555555553f517200000000000000000000000000515151720000000000000000000000563f3e4600000000005151517677520000000000000073507641775200000000003f51520000000000000000000000000051000000000000000000000000006351513e55555555580000000058555555553f
5555555555446565656545555555555551527266000000000000000000635351515152720000535363665300000056555546000053677351515151515172100000007350515151515151720063000000515172000000000000000000000073510000000000000000000000007340515155555555554465656565455555555555
444544454445444544452f454445444551516171000000000000000060764177515151512f76414141414177515144454445517641417751515151515151515151515151515151515151764141775151515161710000000000000000606176777677617100000000000000006061515144454445442f44454445444544454445
45444544454445441f444544454445445151511f5151515151515151785151514544455151516161615161615161515151515151515162000000000000000000000000000000000000000000000000005151515151515151511f51515151515100000000000000000000006051514344454445551f5800000000585555444544
4445000044454445444555580000444551515151515151515161516178515151444543515161620000740000740060515151515151620000000000000000000000000000000000000000001200000000515161615161615151515161615151510000000012000000000000006061444544454355555800000000585555434445
454445000044454445555558004445445151515151515151620074006a606151454445516200000000000000000000515151515151000000000000000000120000000000000000000000000000000000516200007400006051527400007460510000000000000000000000000000434445444555555800000000585555444544
444500000000444544455558000044455151516274515151000000006a000060444561620000000000000000000000606161616162000000000000000000000000001200000000000000000000000000620000000000000060620000000000600000000000000000000000000000444544454355555800300000585555434445
5558000000000058554f5558000058555151510000605162000000007a000000554600000000000000000000000000000000004f00000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000565545444555555800000000585555555555
3e58000000000058554f55580000583f515162000000740000000000000000003e46000000000000000067000000003f3e00004f00000000000000000000000000000000000000636700000000000000000000000000000000000000000000000000000000000000007372000000563f3e45435555580000000058555555553f
5558000000000058554f55580000585551510000000000000000000000000000554600007372100050515152000000000000534f73727350516969696969696969696969696960515162696969696969006300000000000000000000000066006969696969696969695152725363565545444555554465656565455555555555
4445444544454445442f44454445444551510000000000000000000060615151444551515151764141775176417751515176414177515151515959595959595959595959595959595959595959595959767761710000000000000000706151515959595959595959595151764177444544454445442f44454445444544454445
45444544455800001f005844454445444543516161686161615161616861516151620000000000000000000000004344454362000000000000006061516161616161516161616161515151616161616161616161616161616161616151515151454445444579511f5178515151785151454355580000003000001f0058554344
4445444555580000000058554445444544456200007a0015007400006a007400516400000000000000000000000044454445640000000000000000007400000000007400000000006051620000000000000000007400000000740000606151514445444570515151617861516178515144455558000000000000000058554445
454445555558004d00005855554445444543640000000000000000007a000000510000000000635300530000000043444543000000000000000000000000000000000000000000000074000000000000000000000000000000000000000060514544450000746062007a0074006a6051454355580000004a0000000058554344
444555555558000000005855554344454445000000000000000000000000000062000000706176414141777100004445444500000000000000000000000012000000000012000000000000120000000000001200000000000000000000000060444500000000000000000000007a006044455558000000000000000058554445
5555555555580000000058555544454455460000000000000000000000000000000000000000000000000000000056555546000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005546000000000000000000000000000045435558000000000000000058555555
3e55555555580000000058555543443f3e4600000000000000000000000000003e00000000000000000000000000563f3e460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003f554600000000000000000000000000003e45555800000000000000005855553f
5555555555446565656545555544454455460000000000530063535300006700000053530010535300670000000056555546007350516969696969696900000069696900000069696969000000696969690000006969696969695152720000005546737200000000000000000073720045435558000000000000000058555555
444544454445444544452f454445444544455151515176414141414177515151517641414141412f77515151515144454445515151515959595959595959595959595959595959595959595959595959595959595959595959595151515151514351617100000000000000007061515144454445444544452f45444544454445
__sfx__
0001000026050280502b0501c0001d0001e0002000021000220002700028000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002a0502d0502e0501d0001f000210002300024000180001a0001c0001d0001f000210002300024000180001a0001c0001d0001f000210002300024000180001a0001c0001d0001f000210002300024000
00020000270501c050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001d13020130241302800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002415028150291500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001a5431f543235432453321523235132351300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00000e5500e550105501055011550115501855018550175501755013550135501555015540155301552015510155101550000500005000050000500005000050000500005000050000500004000050000500
000400001b0501f050240502b05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000a6500c6500c6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000b6500e6500c6500b65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002e0502b050270500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00000c625000050000500005156250000500005000050c625000050000500005156250000500005000050c625000050000500005156250000500005000050c62500005000050000515625000050000500005
010e00001001210022100321004210052100421002210012100121002210032100421005210042100221001213012130221303213042130521304213022130121101211022110321104211052110421102211012
010e00001055400500135540050015554005001755400000125540000000000005000e5540050000000000001055400500135540050015554005001755400000125540000000000005000e554005000000000000
010e00000e554005000c554005000b5540050009554000000b554000000000000500065540050000000000000e554005000c554005000b5540050009554000000b55400000000000050006554005000000000000
010e00000e0120e0220e0320e0420e0520e0420e0220e0120e0120e0220e0320e0420e0520e0420e0220e0120c0120c0220c0320c0420c0520c0420c0220c0120901209022090320904209052090420902209012
010e00000e153000000000000000000000000000000000000e153000000e153000000e153000000e153000000e153000000000000000000000000000000000000e153000000e153000000e153000000e15300000
010e00000201202012020220202202032020220202202012020120201202022020220203202022020220201202012020120202202022020320202202022020120201202012020220202202032020220202202012
01100000210531d0531c0531505310043100330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001054010530135401353017540175301c5401c5301b5401b5301b5201b5100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000010757107571075710757107571075710757107570f7570f7570f7570f7570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000745006450054500545004600046000640007400054000140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000d76005760127600c76016760127601f760177602d750237402a7301c7202171022710007002171000700007002071000700007002271000700007002071000700007000070000700007000000000000
010300002375022750217501f7501c7501c7501c75000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001553015530155301553015530155301553015530105301053010530105301053010530105301053011530115301153011530115301153011530115300e5300e5300e5300e5300e5300e5300e5300e530
0110000021055000052105521055210550000021055210551c055000051c0551c0551c055000051c0551c0551d055000051d0551d0551d055000051d0551d0551a055000051a0551a0551a055000051a0551a055
010800180201202012020220202202032020220202202012210551f0551d0551a0551805500000260520000026030000002602000000260100000000000000000000000000000000000000000000000000000000
010600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a0000115501155013550135501555015550185501855011550115501355013550155501555018550185501655016550135501355010550105500c5500c5501655016550135501355010550105500c5500c550
010a00000e5500e550105501055011550115501555015550135501355010550105500c5500c5501055010550135501355010550105500c5500c55010550105501355013550135501355013550135501355013550
010a00000e5500e55010550105501155011550135501355011550115500c5500c5500e5500e5500c5500c5500a5500a5500c5500c5500e5500e55010550105501155011550105501055011550115500c5500c550
010a00000e5500e55010550105501155011550135501355011550115500c5500c5500e5500e550115501155010550105501155011550135501355015550155501155011550115501154011530115201151011500
010a00000555300000000000000005553000000000000000055530000000000000000555300000000000000009553000000000000000095530000000000000000955300000000000000009553000000000000000
000200002d6401d640236401b64020640176401e64014640106300f62010610000002c00029000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01424344
04 13144344
01 4b0c4d44
00 4b0c4344
01 4b0c0d10
00 4b0c0d10
00 410f0e10
02 410f0e10
03 11424344
01 1a1b4344
03 18194344
01 1c204344
00 1d204344
00 1e204344
02 1f204344

