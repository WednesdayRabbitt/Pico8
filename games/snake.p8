pico-8 cartridge // http://www.pico-8.com
version 16
__lua__


----------initalisation
function _init()
	state=0
	t=1
	max_app=5
	testing=false
	⧗=-100--gameover screen time
	…=3--start len
	col={b=7,s=11,o=10}
end

----------update
function _update()
	t=(t+1)%2
	if(state==0)then
		_title()
	elseif(state==1)then
		_game()
	elseif(state<0)then
		_over()
	else
		error()
	end--finite states
end--update

----------draw
function _draw()
	tests()
	if (state==0)then--title screen
		cls()
		tests()
		spr(0,26,53,10,3)
	elseif(state==1)then--game
		cls()
		tests()
		draw_border()
		draw_snake()
		draw_apples()
	elseif(state<0)then
		game_over()
	else
		error()
	end
end
-->8
--state==0 :title



function _title()
	--reset
	state=0
	apples={}
	snake={}
	add(snake,{64,64})
	for i=1,… do
		add(snake,{64,64})
	end
	ready=true
	--exit to game
	for i=0,3 do
		if(btnp(i))then
			snake.d=i
			snake.v=nil--init snake vert var
			if(i<=1)then
				snake.v=false
			else
				snake.v=true
			end
			state=1
		end
	end
end
-->8
--state==1 :game

function collision(x,y)
	--collision with self
	for e=2,#snake do
		if(x==snake[e][1])then
			if(y==snake[e][2])then
				return true
			end
		end
	end
	--border
	if(x<1 or x>126)then
		return true
	end
	if(y<1 or y>126)then
		return true
	end
	--apples
	if(#apples>0)then
		for a=1,#apples do
			if(x==apples[a][1] and y==apples[a][2])then
				eat()
				del(apples,apples[a])
				break
			end
		end
	end
end--coll

function check()--coll check
	if(collision(snake[1][1],snake[1][2]))then
		state=⧗
	end
end--check

--add a section to end of snake
function eat()
	add(snake,{snake[#snake][1],snake[#snake][2]})
end--eat

--add apples
function _apple()
--[[	for a=1,max_app-#apples do
		apples[a]={flr(rnd(126)+1),flr(rnd(126)+1)}
	end--]]

---[[
	if(#apples<max_app)then
		add(apples,{flr(rnd(126)+1),flr(rnd(126)+1)})
	end--]]
end

function _game()
	--input
	for i=0,3 do
		if(btnp(i) and ready)then	 --i=dir button
			ready=false															--ready for input?
			if(i<=1)then														--is i horizontal?
				if(snake.v==true)then				--if so,is snake vert?
					snake.d=i															--change snake dir
					snake.v=false											--change snake vert var
					break
				end
			--reverse for this
			else
				if(snake.v==false)then
					snake.d=i
					snake.v=true
					break
				end
			end		--if/else
		end			--btn
	end				--input

	if(t==1)then
		--move snake body
		if(#snake>1)then
			for i=#snake,2,-1 do
				snake[i][1]=snake[i-1][1]
				snake[i][2]=snake[i-1][2]
			end
		end
		--move snake head
		if(snake.d==0)then
			snake[1][1]-=1
			check()
		elseif(snake.d==1)then
			snake[1][1]+=1
			check()
		elseif(snake.d==2)then
			snake[1][2]-=1
			check()
		else
			snake[1][2]+=1
			check()
		end--snake head
	ready=true
	end

	--apple stuff
	_apple()
	
	if(btn(4) and test)then
		eat()
	end
	if(btnp(5) and test)then
		state=⧗
	end
end--end of _game

----------draw snake
function draw_snake()
	for i=1,#snake do
		pset(snake[i][1],snake[i][2],col.s)
	end
end

----------draw border and score
function draw_border()
	line(0,0,127,0,col.b)
	line(0,127,127,127,col.b)
	line(0,0,0,127,col.b)
	line(127,0,127,127,col.b)
	print("score:"..#snake-…-1,2,2,10)
end

----------draw apples
function draw_apples()
	if(#apples>0)then
		for a=1,#apples do
			pset(apples[a][1],apples[a][2],8)
		end
	end
end
-->8
--state==-1:game_over

function _over()
	state+=1
	if(btnp(5))then
		state=0
	end
	for b=0,3 do
		if(btnp(b))then
			state=0
		end
	end
end

----------draw game over
function game_over()
	print("game over",46,60,col.o)
end

-->8
--testing stuff

function tests()
	if(testing)then
		--black background
		rectfill(1,1,20,25,0)
		--state
		print(state,2,2,8)
		--time
		print("time:"..t,7,2,8)
		--direction in green
		print(snake.d,2,18,11)
		--snake length in yellow
		print(#snake,2,10,10)
		--snake pos
		print("x:"..snake[1][1]..',y:'..snake[1][2],7,10,10)
		--#apples
		print(#apples,2,26,9)
		if(#apples>0)then
			for a=1,#apples do
				print("#"..a.."x:"..apples[a][1].." y:"..apples[a][2],2,26+8*a,7)
			end
		end
		--elements of snake
		--[[
		for e=1,#snake do
			for k,v in pairs(snake[e])do
				print("element:"..e,16,20*(e-1),7)
				print("k:"..k..",v:"..v,16,20*(e-1)+6*k,7)
			end
		end
		--]]
	end
end
-->8
--error page

function error()
	cls()
	print("oopsie woopsie")
	print("🅾️w🅾️")
	print("i did a fucky wucky")
end
__gfx__
00007777777700007777777700000000777777777777000077770000777700007777777777770000000000000000000000000000000000000000000000000000
00007777777700007777777700000000777777777777000077770000777700007777777777770000000000000000000000000000000000000000000000000000
00007777777700007777777700000000777777777777000077770000777700007777777777770000000000000000000000000000000000000000000000000000
00007777777700007777777700000000777777777777000077770000777700007777777777770000000000000000000000000000000000000000000000000000
77770000000000007777000077770000777700007777000077770000777700007777000000000000000000000000000000000000000000000000000000000000
77770000000000007777000077770000777700007777000077770000777700007777000000000000000000000000000000000000000000000000000000000000
77770000000000007777000077770000777700007777000077770000777700007777000000000000000000000000000000000000000000000000000000000000
77770000000000007777000077770000777700007777000077770000777700007777000000000000000000000000000000000000000000000000000000000000
77777777777700007777000077770000777777777777000077777777000000007777777700000000000000000000000000000000000000000000000000000000
77777777777700007777000077770000777777777777000077777777000000007777777700000000000000000000000000000000000000000000000000000000
77777777777700007777000077770000777777777777000077777777000000007777777700000000000000000000000000000000000000000000000000000000
77777777777700007777000077770000777777777777000077777777000000007777777700000000000000000000000000000000000000000000000000000000
00000000777700007777000077770000777700007777000077770000777700007777000000000000000000000000000000000000000000000000000000000000
00000000777700007777000077770000777700007777000077770000777700007777000000000000000000000000000000000000000000000000000000000000
00000000777700007777000077770000777700007777000077770000777700007777000000000000000000000000000000000000000000000000000000000000
00000000777700007777000077770000777700007777000077770000777700007777000000000000000000000000000000000000000000000000000000000000
77777777000000007777000077770000777700007777000077770000777700007777777777770000000000000000000000000000000000000000000000000000
77777777000000007777000077770000777700007777000077770000777700007777777777770000000000000000000000000000000000000000000000000000
77777777000000007777000077770000777700007777000077770000777700007777777777770000000000000000000000000000000000000000000000000000
77777777000000007777000077770000777700007777000077770000777700007777777777770000000000000000000000000000000000000000000000000000
__sfx__
000100002705027050270502705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002a5502a550000000000029550295500000000000255502555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
