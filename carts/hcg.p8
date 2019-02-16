pico-8 cartridge // http://www.pico-8.com
version 16
__lua__


function _init()
	state=-1
	test=false
	b_count=0
	
	--curve variables
	itt=6
	size=2
	max_itt=9
	stamp_num=2
	
	--colour variables
	col=7
	bg=1
end

function _draw()
	if(state==-1)then
		_intro()
	elseif(state==0)then
		_setup()
	elseif(state==1)then
		_go()
	elseif(state==2)then
		_colour()
	else
		error()
	end
end

--menu functions
function go_to(x,s)
	print("\x8e: go to "..x.." settings",0,6*11,7)
	if(btnp(4))then
		state=s
		set=0
	end
end

function _blink(r,x)
	b_count=(b_count+1)%20
	if(b_count<10)then
		rectfill(x*4,6*r,x*4+3,6*r+5,10)
	end
end

--scroll through different settings
function _change(n)
	if(btnp(3))then
		set=(set+1)%n
	elseif(btnp(2))then
		set=(set-1)%n
	else
		set=set
	end
end

--draw button
function do_draw()
	print("\x97: draw",0,6*12,7)
	if(btnp(5))then
		state=1
		hilbert(itt)
		stamp={}
		--[[stamp element notes:
		each element should be a table
		with 5 elements each
		1=x coord
		2=y coord
		3=1 for clocwise, -1 for ccw
		4=initial direction
		--]]
		stamp[1]={0,127,1,0}
		stamp[2]={((2^itt)-1)*size,127,-1,0}
		cls(bg)
		counter=0
		--snake init direction
		if(itt%2==0)then
			stamp[1][4]=0
			stamp[2][4]=2
		elseif(itt%2==1)then
			stamp[1][4]=3
			stamp[2][4]=3
		else
			error()
		end
	end
end
-->8
--state==-1    :_intro()
--[[notes:
i eventually want to have button
5 go to settings menue and 4 go 
to an information page about 
this cart, hilbert, and fractals
--]]
function _intro()
	cls()
	print("welcome to",0,0,7)
	print("hilbert curve generator",0,6*1,7)
	go_to("curve",0)

	print("by wednesday rabbitt",0,6*20,10)
end
-->8
--state==0					:_setup()
--[[notes:
--]]
function _setup()
	cls()
	--change what you're setting
	_change(2)
--	print("set:"..set,0,6*3)
	--finite setting states
	if(set==0)then
		_blink(1,11)
 	if(btnp(0) and itt>0)then
 		itt-=1
-- 		print("⬅️",0,0)
 	elseif(btnp(1) and itt<7)then
 		itt+=1
-- 		print("➡️",0,0)
 	else
 		itt=itt
-- 		print("nothing",0,0)
 	end
	elseif(set==1)then
		_blink(2,5)
 	if(btnp(0) and size>1)then
 		size-=1
-- 		print("⬅️",0,0)
 	elseif(btnp(1) and size<127)then
 		size+=1
-- 		print("➡️",0,0)
 	else
 		size=size
-- 		print("nothing",0,0)
 	end
	else
		error()
	end
	
	print("iterations:"..itt,0,6*1,7)
	print("size:"..size,0,6*2,7)
	
	go_to("colour",2)
	do_draw()
end

-->8
--state==2					:_colour()

function _colour()
	cls()
	
	_change(2)
	
	if(set==0)then
 	b_count=(b_count+1)%20
 	if(b_count<10)then
 		rect(0,6,8,14,7)
 	end
 	if(btnp(0))then
 		col=(col-1)%16
 	elseif(btnp(1))then
 		col=(col+1)%16
 	else
 		col=col
 	end
	elseif(set==1)then
 	b_count=(b_count+1)%20
 	if(b_count<10)then
 		rect(0,6*4,8,6*5+2,7)
 	end
 	if(btnp(0))then
 		bg=(bg-1)%16
 	elseif(btnp(1))then
 		bg=(bg+1)%16
 	else
 		bg=bg
 	end
	else
		error()
	end
	
	rectfill(1,7,7,13,col)
	print("line colour:",0,6*0,7)
	
	rectfill(1,6*4+1,7,6*5+1,bg)
	print("background colour:",0,6*3,7)

	go_to("curve",0)
	do_draw()
end
-->8
--state==1					:_go()

--elements of the table output are the negative of the table input
function inverse(j)
	a={}
	for i=1,#j do
		add(a,-(j[i]))
	end
	return a
end

--concat 4 tables together
function cat(a,b,c,d)
	for i=1,#b do
		add(a,b[i])
	end
	for i=1,#c do
		add(a,c[i])
	end
	for i=1,#d do
		add(a,d[i])
	end
	return a
end

--returns table a, the turns in hilbert curve of iteration n
function hilbert(n)
	if(n==0)then
	 turn={}
		return turn
	elseif(n==1)then--base case
	 turn={1,1}
		return turn
	elseif(n%2==0 and n>0)then--even
		local b={1,0}
		local c=hilbert(n-1)
		local d={-1}
		inverse(c)
		cat(a,b,c,d)
		for i=#a,1,-1 do
			add(a,a[i])
		end
		turn=a
		return turn
	elseif(n%2==1 and n>0)then--odd
		local b={0,1}
		local c=hilbert(n-1)
		local d={0}
		inverse(c)
		cat(a,b,c,d)
		for i=#a,1,-1 do
			add(a,a[i])
		end
		turn=a
		return turn
	else
		turn={"error"}
		return turn
	end
end----------hilbert

--modified from snake game
function stomp(n,c)
--	add(curve,{stamp[1],stamp[2],col})
	--make an imprint
	pset(stamp[n][1],stamp[n][2],c)
	--move stamp
	if(stamp[n][4]==0)then
		stamp[n][1]+=1
	elseif(stamp[n][4]==1)then
		stamp[n][2]+=1
	elseif(stamp[n][4]==2)then
		stamp[n][1]-=1
	else
		stamp[n][2]-=1
	end--stamp
end

function _stamp(n)
	if(counter<(#turn/#stamp))then
		if(n==1)then
 		counter+=1
 	end
		for i=1,size do
			stomp(n,col)
		end
		stamp[n][4]=(stamp[n][4]+turn[counter]*stamp[n][3])%4
	end
	if(counter==(#turn/#stamp))then
		if(n==#stamp)then
			counter+=1
--[[
  	for i=1,#stamp do
  		print("x:"..stamp[i][1],0,6*i,11)
  		print("y:"..stamp[i][2],30,6*i,11)
 		end
--]]
		end
 	for i=1,size do
 		stomp(n,col)
 	end
 	stomp(n,col)
	end
end
--]]

function _go()
	for i=1,#stamp do
		_stamp(i)
	end
--	draw stamp
--[[
	for i=1,#curve do
		pset(curve[i][1],curve[i][2],curve[i][3])
	end--]]
	_test()
	if(btnp(4))then
		state=0
	end
end
-->8
--_test()

function _test()
	if(test)then
		if(state==1)then
			for i=1,#turn do
--				print(turn[i],flr(i/22)*12,(i%22)*6-6)
				if(counter==#turn)then
					print("x:"..stamp[1][1],0,0,7)
					print("y:"..stamp[1][2],0,6,7)
				end
			end
		end
	end
end
-->8
--error()

function error()
	cls()
	print("error")
end
