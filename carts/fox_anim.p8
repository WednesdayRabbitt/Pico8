pico-8 cartridge // http://www.pico-8.com
version 16
__lua__


function _init()
	t=0
	
	--fox parts
	fox={}
	fox.state=0
	fox.x=64
	fox.y=64
	fox.t=0
	fox.tail={}
	fox.head={}
	fox.body={}
	fox.tail.a={26,27,26,28}
	fox.tail.b={29,30,29,31}
	fox.tail.x={-14,-14,-14,-14}
	fox.tail.y={}
	
	pal(3,0)
end


function _update()
--[[
	t+=1
--]]	
---[[
	if(btnp(4))then
		fox.t+=1
	end
--]]
	if(btn(0))then
--		fox.x-=1
		fox.state=1
	elseif(btn(1))then
--		fox.x+=1
		fox.state=1
	elseif(btn(2))then
		fox.y-=1
	elseif(btn(3))then
		fox.y+=1
	else
		fox.state=0
		fox.x=fox.x
		fox.y=fox.y
	end
	
	if((t%4)==1)then
		fox.t+=1
	end
	
	if(fox.state==0)then
 	fox[1]={8,fox.x-8,fox.y-4,2,1}
 	fox[2]={0,fox.x-8,fox.y-12,2,2}
 	fox[3]={fox.tail.a[1+fox.t%4],fox.x-11,fox.y-12,1,1}
	elseif(fox.state==1)then
 	fox[1]={8,fox.x-8,fox.y-4,2,1}
 	fox[2]={0,fox.x-8,fox.y-12,2,2}
 	fox[3]={fox.tail.b[1+fox.t%4],fox.x+(fox.tail.x[1+fox.t%4]),fox.y-8,1,1}
	else
 	error()
	end
end


function _draw()
	cls(3)
	for i=1,#fox do
		spr(fox[i][1],fox[i][2],fox[i][3],fox[i][4],fox[i][5])
	end
	pset(fox.x,fox.y,8)
end
-->8
--error()

function error()
	print(error)
end
__gfx__
00000033300003300000033000000000000000000030000000000000003737773730000000000000000373337700000000033333770000000037333377000000
0000003dd30003d3000003d3303300000000000003d3003000000000000377770373337700000000000377777770000000077777777000000003777777700000
00000036d7303d730000036dd33d3000000000003dd303d300000000000377730377777770000000000377777777763000337777777763000003777777776300
000000366773377300000366d73dd300000000003d633dd300000000003777730377777777630000003777736677363003377776677763000037777667776300
000000036777737300000366677337300000000376633d7300000000037773303777367736630000003777333377330003777333377733000377733337773300
000000037777773000000036777773300000000376777373000000003dd733003d7333dd3333000000037dd333dd30003dd73730037d33003dd73300037d3d30
000000337772723000000037777272300000000377777733000000003dd3d3003dd3d33d33d30000000033d33dd300003dd3d300003dd3303dd3d300003dd3d3
0000003667727230000003377772723000000033777777300000000003d3330003dd3d3dd3dd3000000000333d33000003d3d3000003dd3303d333000003dd33
00000033666773330000036677666333000003667772723000000000770000000037333077000000003300000330000000003300000000003330000000000000
0000000036666663000003366666666300000036677272300000000077700000000377737770000003d330003d33000000033d3000000000ddd3300000000000
0000000003333330000000036666633000000003366773330000000077773373000377777777630003dd30003dd300000003dd30333330003d77730000000000
00000000000000000000000033333000000000000336666300000000677773d3003777776777630003d730003d73000000037d30ddd773300337773033300000
000000000000000000000000000000000000000000333330000000003377d33003777336377733000377730003773000003773003d77777300033773ddd33333
0000000000000000000000000000000000000000000000000000000003dd33003dd73303037d3d3003777300037730000037730003377777000003373d777777
000000000000000000000000000000000000000000000000000000003dd330003dd3d300003dd3d3003773000037730000377300000333330000000003377730
000000000000000000000000000000000000000000000000000000003d33000003d333000003dd33003773000003730000037300000000000000000000033300
