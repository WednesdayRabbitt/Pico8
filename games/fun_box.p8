pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--main

function _init()
	page=0
	t=0
	grav=0.9
	test=true
end


function _update()
	if(page==0)then
		_title()
	elseif(page==1)then
		_game()
	end
end


function _draw()
	if(page==0)then
		title()
	elseif(page==1)then
		game()
	else
		error()
	end
end
-->8
--title page

function _title() --update
	t+=1
	
	if(btnp(4 or 5))then
		game_init()
		page+=1
	end
end

function title() --draw
	cls()
	
	local function f_b(i,c)
 	print("f",58-8*c*cos(i),30+8*sin(i),10)
 	print("b",58+8*c*cos(i),30-8*sin(i),10)
 end
	
	print(" un  ox",64-(7*4)/2,30,10)
	if(t%80<20)then
 	f_b(0,1)
	elseif(t%80>=20 and t%80<40)then
		f_b(-t/40,-1)
	elseif(t%80>=40 and t%80<=60)then
 	f_b(0.5,1)
	else
 	f_b(t/40,1)
	end
	
	local str="press z or x to play"
	for x=1,#str do
		print(sub(str,x,x),16+4*x,100+2*cos((t-x)/10),11)
	end
	
	if(test)then
 	pset(64+10*cos(t/40),64+10*sin(t/40),8)
 	pset(64-10*cos(t/40),64-10*sin(t/40),8)
 	pset(64+20*cos(t/30),64+20*sin(t/30),11)
 	pset(64-20*cos(t/30),64-20*sin(t/30),11)
 	pset(64,64,10)
	end
	if(false)then
		for x=16,112 do
			pset(x,112+5*sin((t-x)/15),11)
			print(sub("012345",(t/10%6)+1,(t/10%6)+1),64,64,10)
		end
	end
end
-->8
----- game init

function game_init()
	bodies={}
	cx=0 cy=0--camera x/y
	
	cls()
	for y=0,15 do for x=0,127 do
		local tile=mget(x,y)
		
		if(tile==1)then
			bun=spawn_pl(x*8,y*8)
			bun.typ=plr
		end
	end end
end

function spawn_body(x,y,s,p)
	local b={}
	b.x=x b.y=y b.dx=0 b.dy=0
	b.ddy=grav b.dir=sgn(b.dx)
	b.width=8 b.height=8
	b.ground=false
	b.spr=s b.typ=p
	b.max_y=7 b.max_x=5
 b.jump=6
	b.fric=0.5--also found in update
	
	add(bodies,b)
	return b
end

function spawn_pl(x,y)
	pl=spawn_body(x,y,1)
	
	return pl
end
-->8
-----game update
function _game() --update game
	for b in all(bodies) do
		animate_body(b)
		if(b.typ==plr)then
			ctrl_pl(b)
		end
	end
	
	camera(cx,cy)
	if(test)then
		if(btn(4))then
			if(btn(0))then
				cx-=2
			elseif(btn(1))then
				cx+=2
			elseif(btn(2))then
				cy-=2
			elseif(btn(3))then
				cy+=2
			else
			end
		end
	end
end

function animate_body(b)
	b.x+=b.dx b.y=flr(b.y+b.dy)
	if(b.dy<=b.max_y)then
		b.dy+=b.ddy
	else
		b.dy=b.max_y
	end
	colision(b)
	if(solid(b.x,b.y))then
		b.ground=true
		b.dy=0
	else
		b.ground=false
	end
end

function ctrl_pl(b)
	if(btn(0)and btn(1))then
		b.dx/=1+b.fric
	elseif(btn(1))then
		if(b.dx<b.max_x)then
 		b.dx+=0.5
		end
	elseif(btn(0))then
		if(b.dx>-b.max_x)then
 		b.dx-=0.5
		end
	else
		b.dx/=1+b.fric
	end
	
	if(b.ground)then
		b.fric=0.5
		if(btn(2))then
			b.dy=-b.jump
		end
	else
		b.fric=0
	end
end

function solid(x,y) --test if solid

	local	val=mget(flr(x/8),flr(y/8))
	if(--[[y>(13*8) or]] fget(val,1))then
		return true
	else
		return false
	end
end

function colision(b)
	
	x0=b.x y0=b.y
	
	if(b.dx>=0)then
		x=b.x+b.width/2
	else
		x=b.x-b.width/2-1
	end
	xd=x+b.dx
	
	if(b.dy>=0)then
		y=b.y+1
	else
		y=b.y-b.height
	end
	yd=y+b.dy
	
end
-->8
-----game draw
function game() --draw game
	cls()
	map(0,0,0,0,127,31,2)
	foreach(bodies,draw_body)
	if(test)then
		foreach(bodies,coo)
		foreach(bodies,colisionchq)
	end
end

function draw_body(b)
	spr(b.spr,b.x-b.width/2,b.y-b.height+1)
	if(test)then
		print(b.ground,b.x-8,b.y-14,12)
		pset(b.x,b.y,8)
	end
end

function coo(b)
	local val=mget(flr(b.x/8),flr(b.y/8))
	print("x:"..flr(b.x).." dx:"..b.dx,2,2,12)
	print("y:"..b.y.." dy:"..b.dy,2,10,12)
	print(val.." "..fget(val),2,18,12)
end


function colisionchq(b)
	x0=b.x y0=b.y
	if(b.dx>=0)then
		x=b.x+b.width/2+b.dx
	else
		x=b.x-b.width/2+b.dx-1
	end
	
	if(b.dy>=0)then
		y=b.y+b.dy+1
	else
		y=b.y-b.height+b.dy
	end
	
	-- x direction
	if(solid(x,y0))then
		pset(x,y0,10)
		
	end
	
	-- y direction
	if(solid(x0,y))then
		pset(x0,y,10)
	end
end
-->8
--error()

function error()
	cls(8)
	print(error)
end
__gfx__
00000000dddddddd7777777788888888bbbbbbbbb3b3b3bbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000d177711d7600006782777728b44444443bb33b334444444b44444444b444444b00000000000000000000000000000000000000000000000000000000
00700700d171171d7606666782722228b4444444444444444444444b44444444b444444b00000000000000000000000000000000000000000000000000000000
00077000d177711d7600066782777228b4444444444444444444444b44444444b444444b00000000000000000000000000000000000000000000000000000000
00077000d171171d7606666782722228b4444444444444444444444b44444444b444444b00000000000000000000000000000000000000000000000000000000
00700700d171171d7606666782722228b4444444444444444444444b44444444b444444b00000000000000000000000000000000000000000000000000000000
00000000d177711d7606666782777728b4444444444444444444444b44444444b444444b00000000000000000000000000000000000000000000000000000000
00000000dddddddd7777777788888888b4444444444444444444444bbbbbbbbbb444444b00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444bbbbbbbb4444444bbbbbbbbb44444444bbbbbbbb000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444b444444b4444444bb4444444444444444444444b000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444b444444b4444444bb4444444444444444444444b000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444b444444b4444444bb4444444444444444444444b000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444b444444b4444444bb4444444444444444444444b000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444b444444b4444444bb4444444444444444444444b000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444b444444b4444444bb4444444444444444444444b000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444bbbbbbbb4444444bbbbbbbbb44444444bbbbbbbb000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444444444444444444bb444444bb444444b00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444444444444444444bb444444bb444444b00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444444444444444444bb444444bb444444b00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444444444444444444bb444444bb444444b00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444444444444444444bb444444bb444444b00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444444444444444444bb444444bb444444b00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4444444444444444444444bb444444bb444444b00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbb444444bbbbbbbbb00000000000000000000000000000000000000000000000000000000
__gff__
0004000002020202020000000000000000000000020202020202000000000000000000000202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
1600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
1600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
1600000000000000000000000000000000000000000000000000000000000000000000000004070719000000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
1600000000000000000000000000000000000000000000000000000000000000000000000027000000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
1600000000000000000000000000000000000000000000000000000000000000000000000027000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
1600000000000000000000000000000000000000000000000000000000000000000000000027000008000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
1600000000000000000000000000000000000000000000000000000000000000000000000024070726000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
1600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
1600000000000000000000000000000000000000000000000000000000170707070707190000000000000000000000000000000000000000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
1600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
1600010000000200000000000000000000000405050505050505060000000000000000000000040600000000000000000000000004050506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
1600000000000000000000000000000000001418181818181818160000000000000000000000141600000000000000000405050518181816000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
1600000000000000000505000000000004051818181818181818160000000000000000000000141600000000040505051818181818181816000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015
0405050505050505050505050505050518181818181818181818180505050505050505050505181805050505181818181818181818181818050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
1418181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818181818
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101000000000000000000000000000000000000000000000000000000000000000001010101010101010101010101010101010100000101010101010100000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000101000100000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000