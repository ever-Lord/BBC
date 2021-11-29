local Public = {}

-- EVL List of sendings played in BBC (sorted by GameId)

-- Copy/paste Public.detail_game_id[xxx] and set the values from saved game 
-- (go to fish>mutagen_log and select team north or south to get the sendings)
-- (or with whatever you want)
-- Be sure gameId is not already used

-- Note: in simulation mode, your sendings are still sent to self (ie added to pattern) --TODO--

-- or ask everLord#4340 in discord to get the fully formatted pattern you need.

-- "pack_01"="Regular" "pack_02"="Science" "pack_03"="Robots" "pack_04"="Combat"

Public.detail_game_id = {}

--[[
--Debugging pattern
Public.detail_game_id[1] ={ ["Team"]="SteelaxeMafia", ["Info"]="Debugging pattern", ["Pack"]="pack_02", ["Versus"]="OldGuard", ["Date"]="07 nov 21",
	["Pattern"]={
		[1]={"automation",16,"logistic",1,"chemical",0},
		[2]={"logistic",10},
		[4]={"logistic",19},
		[5]={"logistic",84},
		[6]={"logistic",64},
		[13]={"logistic",146},
		[14]={"logistic",100},
		[15]={"logistic",150},
		[16]={"logistic",150},
		[17]={"logistic",150},
		[18]={"logistic",150},
		[19]={"logistic",150,"automation",32,"chemical",50,"utility",50,"space",50},
		[20]={"logistic",200},
		[21]={"logistic",200},
		[22]={"logistic",200},
		[23]={"logistic",200},
		[24]={"logistic",200},
		[25]={"logistic",200},
		[26]={"logistic",200},
		[27]={"logistic",200},
		[28]={"logistic",200},
		[999]={"logistic",200,"automation",32,"production",50}
	}
}
--Debugging pattern
Public.detail_game_id[2] ={ ["Team"]="SteelaxeMafia", ["Info"]="Debugging pattern", ["Pack"]="pack_02", ["Versus"]="OldGuard", ["Date"]="07 nov 21",
	["Pattern"]={
		[1]={"automation",1,"logistic",1,"chemical",1},
		[2]={"logistic",5,"automation",1},
		[4]={"logistic",9},
		[5]={"logistic",4},
		[6]={"logistic",4},
		[7]={"automation",15,"logistic",3,"chemical",0,"utility",0,"space",0},
		[999]={"automation",200,"logistic",32,"production",50}
	}
}
]]--

--Burner logistic rush by SteelaxeMafia vs The Old Guard on 07 nov 21, gameId=1845
Public.detail_game_id[1845] ={ ["Team"]="SteelaxeMafia", ["Info"]="Burner logistic rush", ["Pack"]="pack_02", ["Versus"]="OldGuard", ["Date"]="07 nov 21",
	["Pattern"]={
		[7]={"logistic",32},
		[8]={"logistic",50},
		[9]={"logistic",19},
		[10]={"logistic",84},
		[11]={"logistic",64},
		[13]={"logistic",146},
		[999]={"logistic",200}
	}
}

--Mafia vs Mysticlutch on 28 nov 21, gameId=2214
Public.detail_game_id[2214] ={ ["Team"]="SteelAxeMafia", ["Info"]="Green rush", ["Pack"]="pack_01", ["Versus"]="Mysticlutch", ["Date"]="28 nov 21",
	["Pattern"]={
		[7]={"logistic",10},
		[8]={"logistic",10},
		[9]={"logistic",56},
		[10]={"logistic",61},
		[11]={"logistic",169},
		[12]={"logistic",86},
		[13]={"logistic",132},
		[14]={"logistic",61},
		[15]={"logistic",88},
		[16]={"logistic",151},
		[17]={"logistic",195},
		[18]={"logistic",88},
		[19]={"logistic",136},
		[20]={"logistic",85},
		[21]={"logistic",132},
		[22]={"logistic",63},
		[23]={"logistic",190},
		[24]={"logistic",249},
		[25]={"logistic",143},
		[27]={"logistic",126},
		[28]={"logistic",144},
		[29]={"logistic",71},
		[31]={"logistic",252},
		[34]={"logistic",300},
		[37]={"logistic",459},
		[40]={"logistic",407},
		[42]={"logistic",517},
		[43]={"logistic",138},
		[44]={"logistic",110},
		[45]={"logistic",184},
		[47]={"logistic",10},
		[48]={"logistic",97},
		[50]={"logistic",161},
		[51]={"logistic",105},
		[52]={"logistic",55},
		[53]={"logistic",133},
		[999]={"logistic",200}
	}	
}

--Mafia vs Mysticlutch on 28 nov 21, gameId=2214
Public.detail_game_id[2215] ={ ["Team"]="Mysticlutch", ["Info"]="Green rush", ["Pack"]="pack_01", ["Versus"]="SteelAxeMafia", ["Date"]="28 nov 21",
	["Pattern"]={
		[7]={"logistic",34},
		[9]={"automation",23,"logistic",58},
		[10]={"automation",8,"logistic",43},
		[11]={"automation",34,"logistic",28},
		[14]={"automation",69,"logistic",142},
		[15]={"automation",35,"logistic",14},
		[17]={"logistic",111},
		[19]={"automation",23,"logistic",95},
		[20]={"automation",9,"logistic",107},
		[22]={"logistic",111},
		[25]={"automation",15,"logistic",215},
		[27]={"logistic",159},
		[28]={"logistic",83},
		[31]={"logistic",241},
		[37]={"automation",9,"logistic",568},
		[42]={"automation",60,"logistic",440},
		[46]={"automation",62,"logistic",373},
		[48]={"logistic",219},
		[53]={"automation",171,"logistic",566},
		[999]={"logistic",200}
	}	
}






--Mili x10 into Blue x21(+20) by Steelaxe on 22 nov 21, gameId=2583
Public.detail_game_id[2583] ={ ["Team"]="Steelaxe", ["Info"]="Milix10 into Bluex21(+20)", ["Pack"]="pack_04", ["Versus"]="SteelAxeMafia", ["Date"]="22 nov 21",
	["Pattern"]={
		[21]={"military",10},
		[23]={"military",19},
		[27]={"military",30},
		[32]={"military",82},
		[33]={"automation",6,"logistic",68},
		[37]={"military",157},
		[40]={"military",88},
		[42]={"military",93},
		[49]={"military",171},
		[53]={"military",181},
		[61]={"military",113},
		[64]={"military",91},
		[66]={"military",108},
		[68]={"chemical",101},
		[70]={"military",152},
		[71]={"chemical",171},
		[75]={"chemical",215},
		[81]={"chemical",506},
		[85]={"chemical",231},
		[87]={"chemical",186},
		[89]={"automation",202,"logistic",201,"chemical",174},		
		[93]={"chemical",276},
		[94]={"military",35},
		[96]={"chemical",200},
		[102]={"chemical",120},
		[111]={"chemical",222},
		[119]={"automation",330,"logistic",364,"military",87,"chemical",1655},		
		[126]={"chemical",632},
		[127]={"automation",76,"chemical",379},
		[128]={"chemical",108},
		[130]={"chemical",261},
		[999]={"chemical",200}
	}
}
--Burner green rush x40 by SteelaxeMafia on 22 nov 21, gameId=2583
Public.detail_game_id[2584] ={ ["Team"]="SteelaxeMafia", ["Info"]="Burner green rush x40", ["Pack"]="pack_04", ["Versus"]="SteelAxe", ["Date"]="22 nov 21",
	["Pattern"]={
		[10]={"logistic",21},
		[11]={"logistic",28},
		[12]={"logistic",64},
		[14]={"logistic",101},
		[15]={"logistic",98},
		[16]={"logistic",226},
		[17]={"logistic",134},
		[18]={"logistic",140},
		[19]={"logistic",108},
		[20]={"logistic",94},
		[22]={"logistic",275},
		[24]={"logistic",77},
		[26]={"logistic",249},
		[30]={"logistic",523},
		[32]={"logistic",73},
		[33]={"automation",6,"logistic",68},
		[34]={"logistic",223},
		[35]={"logistic",67},
		[37]={"logistic",182},
		[38]={"logistic",209},
		[40]={"logistic",83},
		[42]={"logistic",304},
		[45]={"logistic",438},
		[47]={"logistic",178,"military",70},
		[48]={"logistic",270},
		[50]={"logistic",163,"military",24},
		[51]={"logistic",217,"military",2},
		[52]={"logistic",171,"military",16},
		[53]={"logistic",171},
		[54]={"logistic",308,"military",18},
		[55]={"logistic",243,"military",10},
		[56]={"logistic",67},
		[58]={"logistic",238},
		[59]={"logistic",85,"military",30},
		[60]={"logistic",145,"military",12},
		[61]={"logistic",93},
		[63]={"logistic",259},
		[64]={"logistic",127},
		[65]={"logistic",54},
		[68]={"logistic",364},
		[69]={"logistic",115},
		[71]={"logistic",426},
		[73]={"logistic",414},
		[75]={"military",102},
		[78]={"logistic",192},
		[85]={"logistic",9,"military",91},
		[87]={"logistic",323},
		[92]={"logistic",411},
		[102]={"logistic",149,"military",44},
		[104]={"logistic",45},
		[107]={"logistic",198,"military",6},
		[110]={"logistic",113},
		[115]={"automation",144,"logistic",569,"military",112},
		[119]={"automation",219,"logistic",397,"military",29,"chemical",46},
		[120]={"military",26},
		[123]={"logistic",234},
		[124]={"automation",216,"logistic",158,"military",106},
		[125]={"automation",44,"logistic",73},
		[126]={"automation",51},
		[127]={"logistic",75},
		[128]={"logistic",12},
		[129]={"logistic",198,"chemical",36},
		[130]={"chemical",4},
		[999]={"logistic",200}
	}	
}

--Spam green x60 by Green Science Dutch  (north) on 25 nov 21, gameId=2829
Public.detail_game_id[2829] ={ ["Team"]="Green Science Dutch", ["Info"]="Spam green x60", ["Pack"]="pack_01", ["Versus"]="C4", ["Date"]="25 nov 21",
	["Pattern"]={
		[23]={"logistic",142},
		[26]={"logistic",403},
		[28]={"logistic",112},
		[30]={"logistic",323},
		[35]={"logistic",917},
		[38]={"logistic",275},
		[40]={"logistic",326},
		[46]={"logistic",1268},
		[51]={"logistic",1272},
		[60]={"logistic",1963},
		[62]={"logistic",493},
		[67]={"logistic",869},
		[69]={"logistic",629},
		[70]={"military",2},
		[76]={"automation",47,"logistic",1988},
		[999]={"logistic",300}
	}	
}

--Spam green x60 by C4 (south) on 25 nov 21, gameId=2829
Public.detail_game_id[2830] ={ ["Team"]="C4", ["Info"]="Spam green x60", ["Pack"]="pack_01", ["Versus"]="Green Science Dutch", ["Date"]="25 nov 21",
	["Pattern"]={
		[20]={"logistic",549},
		[23]={"logistic",291},
		[27]={"logistic",322},
		[29]={"logistic",103},
		[31]={"logistic",214},
		[34]={"logistic",262},
		[41]={"logistic",1101},
		[45]={"logistic",1018},
		[47]={"automation",2,"military",2},
		[48]={"logistic",1004},
		[51]={"logistic",712},
		[58]={"logistic",2185},
		[60]={"automation",4,"military",1},		
		[62]={"automation",2,"logistic",822},
		[66]={"logistic",1514},
		[68]={"logistic",675},
		[70]={"automation",2,"logistic",586},
		[74]={"logistic",1231},
		[77]={"automation",2,"logistic",713},
		[999]={"logistic",300}
	}	
}
--Spam green x60 by C4 (south) on 26 nov 21, gameId=2952
Public.detail_game_id[2952] ={ ["Team"]="SteelAxeMafia", ["Info"]="Spam green x30", ["Pack"]="pack_01", ["Versus"]="Baguette", ["Date"]="26 nov 21",
	["Pattern"]={
		[6]={"logistic",34},
		[7]={"logistic",25},
		[8]={"logistic",100},
		[9]={"logistic",33},
		[10]={"logistic",50},
		[11]={"logistic",159},
		[12]={"automation",2,"logistic",111},
		[13]={"automation",9,"logistic",27},
		[999]={"logistic",200}
	}	
}
-- TheOldGuard vs SteelAxe 28 nov 21
Public.detail_game_id[3075] ={ ["Team"]="SteelAxe", ["Info"]="Milix10 into Bluex21", ["Pack"]="pack_01", ["Versus"]="TheOldGuard", ["Date"]="28 nov 21",
	["Pattern"]={
		[15]={"automation",156,"logistic",146},
		[16]={"logistic",1},
		[17]={"automation",44,"logistic",6},
		[23]={"automation",121},
		[24]={"military",45},
		[25]={"logistic",44,"military",44},
		[27]={"military",53},
		[31]={"automation",108,"logistic",44,"military",67},
		[33]={"automation",56,"logistic",41,"military",124},
		[36]={"automation",60,"logistic",39,"military",131},
		[38]={"military",104},
		[39]={"automation",84,"logistic",59},
		[40]={"automation",31,"logistic",23},
		[41]={"automation",20,"logistic",14},
		[44]={"military",267},
		[45]={"automation",23,"logistic",2},
		[47]={"military",145},
		[49]={"automation",41,"logistic",48,"military",161},
		[52]={"military",198},
		[57]={"military",192},
		[59]={"automation",94,"logistic",108,"military",82},
		[60]={"military",80},
		[67]={"chemical",64},
		[69]={"military",188,"chemical",44},
		[70]={"automation",116,"logistic",129,"military",77,"chemical",114},
		[71]={"automation",23,"logistic",25},
		[72]={"military",61,"chemical",127},
		[999]={"logistic",200,"military",75,"chemical",125}
	}	
}

-- TheOldGuard vs SteelAxe 28 nov 21
Public.detail_game_id[3076] ={ ["Team"]="TheOldGuard", ["Info"]="Burner green rush x50", ["Pack"]="pack_01", ["Versus"]="SteelAxe", ["Date"]="28 nov 21",
	["Pattern"]={
		[6]={"automation",91},
		[7]={"automation",108},
		[8]={"automation",158},
		[9]={"automation",164},
		[10]={"automation",142},
		[11]={"automation",91},
		[12]={"logistic",19},
		[14]={"logistic",77},
		[15]={"automation",22,"logistic",38},
		[16]={"logistic",46},
		[17]={"logistic",40},
		[18]={"logistic",60},
		[20]={"automation",5,"logistic",222},
		[21]={"logistic",139},
		[24]={"logistic",215},
		[25]={"logistic",35},
		[26]={"logistic",118},
		[28]={"logistic",110},
		[29]={"logistic",53},
		[32]={"logistic",450},
		[33]={"automation",35,"logistic",23},
		[35]={"logistic",475},
		[36]={"automation",1,"logistic",150},
		[37]={"logistic",257},
		[39]={"logistic",427},
		[40]={"logistic",8},
		[42]={"logistic",526},
		[44]={"logistic",228},
		[45]={"logistic",239},
		[46]={"logistic",48},
		[47]={"logistic",21},
		[51]={"logistic",35},
		[52]={"logistic",778},
		[57]={"automation",55,"logistic",964,"military",42},
		[58]={"logistic",274},
		[59]={"logistic",66},
		[60]={"logistic",96},
		[61]={"logistic",269},
		[62]={"logistic",427},
		[65]={"logistic",115},
		[67]={"logistic",476},
		[68]={"logistic",351},
		[70]={"automation",6,"logistic",212},
		[999]={"logistic",350}
	}	
}



--[[ STRESS TEST
Public.detail_game_id[3] ={ ["Team"]="Debug", ["Info"]="Debug", ["Pack"]="pack_01", ["Versus"]="Debug", ["Date"]="Debug", ["Pattern"]={}}
for _i=1,300 do
	Public.detail_game_id[3]["Pattern"][_i]={"logistic",300}
end
Public.detail_game_id[3]["Pattern"][999]={"logistic",300}
]]--


--Construct list of gameId for drop-down in team_manager>config training;  also searching for last minute of sendings
Public.list_game_id = {"[color=#444444]select patternId[/color]","[color=#880000]none (off)[/color]"}
for gameId, pattern in pairs(Public.detail_game_id) do
	table.insert(Public.list_game_id,gameId)
	local _last_time=0
	for _time,_ in pairs(pattern["Pattern"]) do
		if _time~=999 and _time>_last_time then _last_time=_time end
	end
	Public.detail_game_id[gameId]["Last"]=_last_time
	
end

return Public