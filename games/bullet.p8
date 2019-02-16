pico-8 cartridge // http://www.pico-8.com
version 15
__lua__

function add_entity(name,x,y)
	local a={}
	a.name=name
	a.x=x
	a.y=y
	
	if(not entities[name])then
		entities[name]=a
--	else
--		add(entities[name],a)
	end
end

function _init()
	entities={}
	add_entity("player",50,50)
	add_entity("alien",10,5)
	add_entity("alien",15,5)
end

function _draw()
	cls()
	for i in all(entities)do
		print(i)
		for k,v in pairs(entities[i])do
			print("->  k: ".._k.." v: ".._v)
		end
	end
end
__gfx__
00000000000bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000bbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000bb11bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000bbb11bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000bbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700888008880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000080000808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
