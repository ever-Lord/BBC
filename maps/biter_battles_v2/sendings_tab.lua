local Public = {}

-- EVL List of sendings played in BBC (sorted by GameId)

-- Copy/paste Public.detail_game_id[xxx] and set the values from saved game 
-- (go to fish>mutagen_log and select team north or south to get the sendings)
-- (or with whatever you want)
-- Be sure gameId is not already used

-- Note: in simulation mode, your sendings are sent to other team (ie simulator)
-- Note : minute 999 like `[999]={"logistic",200,"automation",32,"production",50}` is what is sent every minute after last sending of pattern(
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
-- SteelAxe Mafia vs C4 on 30 oct 21, gameId=1353
Public.detail_game_id[1353] ={ ["Team"]="Steelaxe Mafia", ["Info"]="Green rush", ["Pack"]="pack_02", ["Versus"]="C4", ["Date"]="30 oct 21",
	["Pattern"]={
       [9] = {"logistic",3},
       [10] = {"logistic",16},
       [11] = {"logistic",19},
       [12] = {"logistic",52},
       [13] = {"logistic",50},
       [15] = {"logistic",100},
       [16] = {"logistic",56},
       [17] = {"logistic",5},
       [18] = {"logistic",105},
       [19] = {"logistic",118},
       [20] = {"automation",2},
       [21] = {"logistic",115},
       [22] = {"logistic",107},
       [24] = {"logistic",185},
       [26] = {"logistic",279},
       [27] = {"logistic",70},
       [28] = {"logistic",63},
       [29] = {"logistic",171},
       [30] = {"logistic",117},
       [33] = {"logistic",274},
       [34] = {"logistic",64},
		[999]= {"logistic",200}
	}	
}
Public.detail_game_id[1354] ={ ["Team"]="C4", ["Info"]="Green rush", ["Pack"]="pack_02", ["Versus"]="Steelaxe Mafia", ["Date"]="30 oct 21",
	["Pattern"]={
       [12] = {"logistic",206},
       [15] = {"logistic",259},
       [17] = {"logistic",180},
       [18] = {"automation",12,"logistic",67},
       [20] = {"logistic",194},
       [21] = {"logistic",8},
       [22] = {"logistic",209},
       [25] = {"logistic",432},
       [26] = {"logistic",75},
       [28] = {"logistic",275},
       [29] = {"logistic",35},
       [34] = {"logistic",254},
		[999]= {"logistic",150}
	}	
}
--Burner logistic rush by SteelaxeMafia vs The Old Guard on 07 nov 21, gameId=1845
Public.detail_game_id[1845] ={ ["Team"]="Steelaxe Mafia", ["Info"]="Burner logistic rush", ["Pack"]="pack_02", ["Versus"]="Old Guard", ["Date"]="07 nov 21",
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
-- MysticlutchPipenator vs C4 on 06 nov 21, gameId=1968
Public.detail_game_id[1968] ={ ["Team"]="Mysticlutch", ["Info"]="Green rush", ["Pack"]="pack_01", ["Versus"]="C4", ["Date"]="06 nov 21",
    ["Pattern"]={
        [18] = {"logistic",69},
        [23] = {"logistic",116},
        [25] = {"logistic",89},
        [30] = {"automation",212,"logistic",123},
        [35] = {"logistic",52},
        [38] = {"logistic",28},
        [42] = {"logistic",29},
        [45] = {"automation",212,"logistic",148},
        [53] = {"logistic",133},
        [999]= {"logistic",150}
    }    
}
Public.detail_game_id[1969] ={ ["Team"]="C4", ["Info"]="Green rush", ["Pack"]="pack_01", ["Versus"]="Mysticlutch", ["Date"]="06 nov 21",
    ["Pattern"]={
        [19] = {"logistic",21},
        [22] = {"logistic",160},
        [24] = {"logistic",177},
        [26] = {"logistic",169},
        [27] = {"logistic",100},
        [28] = {"logistic",64},
        [30] = {"logistic",207},
        [35] = {"logistic",183},
        [36] = {"logistic",177},
        [40] = {"logistic",225},
        [43] = {"logistic",345},
        [46] = {"logistic",184},
        [48] = {"logistic",433},
        [50] = {"automation",5,"logistic",179},
        [51] = {"logistic",245},
        [54] = {"logistic",522},
        [57] = {"logistic",202},
        [58] = {"logistic",15},
        [59] = {"logistic",298},
        [62] = {"logistic",489},
        [65] = {"automation",2,"logistic",551},
        [66] = {"logistic",246},
        [999]= {"logistic",200}
    }    
}
--Mafia vs Mysticlutch on 28 nov 21, gameId=2214
Public.detail_game_id[2214] ={ ["Team"]="Steelaxe Mafia", ["Info"]="Green rush", ["Pack"]="pack_01", ["Versus"]="Mysticlutch", ["Date"]="28 nov 21",
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
Public.detail_game_id[2215] ={ ["Team"]="Mysticlutch", ["Info"]="Green rush", ["Pack"]="pack_01", ["Versus"]="Steelaxe Mafia", ["Date"]="28 nov 21",
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
Public.detail_game_id[2583] ={ ["Team"]="SteelAxe", ["Info"]="Milix10 into Bluex21(+20)", ["Pack"]="pack_04", ["Versus"]="Steelaxe Mafia", ["Date"]="22 nov 21",
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
Public.detail_game_id[2584] ={ ["Team"]="Steelaxe Mafia", ["Info"]="Burner green rush x40", ["Pack"]="pack_04", ["Versus"]="SteelAxe", ["Date"]="22 nov 21",
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
-- Baguette vs C4 on 19 nov 21, gameId=2706
Public.detail_game_id[2706] ={ ["Team"]="Baguette", ["Info"]="Green rush", ["Pack"]="pack_01", ["Versus"]="C4", ["Date"]="19 nov 21",
	["Pattern"]={
        [13] = {"automation",45,"logistic",67},
        [16] = {"automation",41,"logistic",50},
        [24] = {"automation",49,"logistic",217},
        [29] = {"automation",56,"logistic",141},
        [31] = {"military",61},
        [36] = {"automation",45,"logistic",86},
        [37] = {"military",268},
        [38] = {"military",173},
        [39] = {"military",76},
        [41] = {"logistic",27,"military",88},
        [42] = {"automation",28,"military",42},
        [43] = {"military",97},
        [45] = {"military",148},
        [46] = {"military",173},
        [48] = {"automation",40,"logistic",53},
        [51] = {"military",238},
        [55] = {"automation",178,"logistic",313,"military",317},
        [57] = {"automation",85,"logistic",77},
        [59] = {"military",175},
        [60] = {"military",38},
        [64] = {"military",260},
        [65] = {"military",28},
        [66] = {"automation",139,"logistic",307,"military",113},
        [67] = {"military",29},
        [68] = {"military",88},
        [71] = {"military",300},
        [72] = {"military",72},
        [74] = {"military",169},
        [75] = {"automation",102,"logistic",271,"military",85},
        [76] = {"military",189},
        [999]= {"automation",25,"logistic",50,"military",150}
	}	
}
Public.detail_game_id[2707] ={ ["Team"]="C4", ["Info"]="Green rush", ["Pack"]="pack_01", ["Versus"]="Baguette", ["Date"]="19 nov 21",
	["Pattern"]={
       [13] = {"automation",2},
       [18] = {"logistic",196},
       [19] = {"logistic",3},
       [25] = {"logistic",594},
       [29] = {"logistic",502},
       [30] = {"logistic",113},
       [33] = {"logistic",296},
       [34] = {"logistic",488},
       [36] = {"logistic",123},
       [40] = {"logistic",756},
       [41] = {"logistic",116},
       [45] = {"logistic",791},
       [46] = {"logistic",261},
       [50] = {"logistic",991},
       [51] = {"logistic",96},
       [52] = {"logistic",88},
       [55] = {"logistic",529},
       [57] = {"automation",4,"logistic",4},
       [59] = {"logistic",872},
       [62] = {"logistic",329},
       [64] = {"logistic",320},
       [68] = {"automation",24,"logistic",546,"military",25},
       [69] = {"logistic",26,"automation",27,"military",3},
       [73] = {"logistic",3},
       [76] = {"logistic",9},
		[999]= {"logistic",150,"military",10}
	}	
}
--Spam green x60 by Green Science Dutch  (north) on 25 nov 21, gameId=2829
Public.detail_game_id[2829] ={ ["Team"]="Green Science", ["Info"]="Spam green x60", ["Pack"]="pack_01", ["Versus"]="C4", ["Date"]="25 nov 21",
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
Public.detail_game_id[2830] ={ ["Team"]="C4", ["Info"]="Spam green x60", ["Pack"]="pack_01", ["Versus"]="Green Science", ["Date"]="25 nov 21",
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
--Spam green x30 by Steelaxe Mafia on 26 nov 21, gameId=2952 (baguette has not sent anything lul, 12min game)
Public.detail_game_id[2952] ={ ["Team"]="Steelaxe Mafia", ["Info"]="Spam green x30", ["Pack"]="pack_01", ["Versus"]="Baguette", ["Date"]="26 nov 21",
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
Public.detail_game_id[3075] ={ ["Team"]="SteelAxe", ["Info"]="Milix10 into Bluex21", ["Pack"]="pack_01", ["Versus"]="Old Guard", ["Date"]="28 nov 21",
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
Public.detail_game_id[3076] ={ ["Team"]="Old Guard", ["Info"]="Burner green rush x50", ["Pack"]="pack_01", ["Versus"]="SteelAxe", ["Date"]="28 nov 21",
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

Public.detail_game_id[3198] = { ["Team"]="Baguette", ["Info"]="Greenx20 into Blue", ["Pack"]="pack_01", ["Versus"]="Old Guard", ["Date"]="03 dec 21",
    ["Pattern"]={
       [22]={"logistic",61},
       [25]={"logistic",50},
       [30]={"logistic",257},
       [35]={"logistic",505},
       [37]={"logistic",217},
       [38]={"logistic",88},
       [42]={"logistic",342},
       [43]={"logistic",117},
       [45]={"logistic",124},
       [49]={"logistic",482},
       [52]={"logistic",394},
       [60]={"logistic",732},
       [64]={"logistic",427},
       [69]={"logistic",452},
       [70]={"logistic",27},
       [72]={"logistic",228},
       [74]={"logistic",158},
       [77]={"logistic",320},
       [78]={"logistic",182,"chemical",32},
       [79]={"logistic",111,"chemical",40},
       [83]={"logistic",431,"chemical",75},
       [85]={"chemical",51},
       [86]={"logistic",254},
       [87]={"chemical",52},
       [999]={"logistic",150,"chemical",50}
    }
}
Public.detail_game_id[3199] = { ["Team"]="Old Guard", ["Info"]="Green into mili x10", ["Pack"]="pack_01", ["Versus"]="Baguette", ["Date"]="03 dec 21",
    ["Pattern"]={
       [6]={"automation",31},
       [7]={"automation",67},
       [8]={"automation",34},
       [9]={"automation",72},
       [10]={"automation",62},
       [11]={"automation",36},
       [12]={"automation",103},
       [13]={"automation",31},
       [14]={"automation",73},
       [16]={"automation",78},
       [17]={"automation",69},
       [19]={"automation",1,"logistic",70},
       [21]={"logistic",106},
       [22]={"logistic",31},
       [24]={"automation",116,"logistic",76},
       [25]={"automation",4,"logistic",147},
       [26]={"logistic",84},
       [28]={"logistic",171},
       [31]={"logistic",175},
       [34]={"logistic",338},
       [36]={"logistic",60},
       [37]={"logistic",118},
       [41]={"automation",83,"logistic",326},
       [42]={"logistic",88},
       [48]={"logistic",492,"military",72},
       [51]={"logistic",259,"military",54},
       [53]={"military",70},
       [54]={"logistic",160},
       [56]={"military",108},
       [58]={"military",80},
       [60]={"military",43},
       [61]={"logistic",122,"military",16},
       [62]={"military",148},
       [64]={"military",84},
       [68]={"logistic",100,"military",60},
       [70]={"military",7},
       [75]={"automation",18,"logistic",11},
       [76]={"military",8},
       [78]={"logistic",469,"military",16},
       [82]={"logistic",71,"military",36},
       [85]={"military",138},
       [999]={"logistic",200,"military",100}
    }
}

Public.detail_game_id[3321] = { ["Team"]="Green Science", ["Info"]="Green Rush", ["Pack"]="pack_03", ["Versus"]="Mysticlutch", ["Date"]="12 dec 21",
    ["Pattern"]={
       [17]={"logistic",147},
       [20]={"logistic",72},
       [23]={"logistic",296},
       [24]={"logistic",43},
       [28]={"logistic",139},
       [32]={"logistic",385},
       [34]={"logistic",60},
       [35]={"logistic",70},
       [42]={"logistic",291},
       [43]={"logistic",212},
       [44]={"logistic",62},
       [46]={"logistic",620},
       [51]={"logistic",424},
       [56]={"logistic",327},
       [68]={"logistic",443},
       [75]={"logistic",488},
       [89]={"logistic",397,"military",176},
       [999]={"logistic",0,"military",0,"chemical",0}
    }
}
Public.detail_game_id[3322] = { ["Team"]="Mysticlutch", ["Info"]="Red/Green Rush", ["Pack"]="pack_03", ["Versus"]="Green Science", ["Date"]="12 dec 21",
    ["Pattern"]={
       [16]={"automation",82,"logistic",66},
       [17]={"automation",12,"logistic",91},
       [19]={"automation",11,"logistic",142},
       [21]={"automation",62,"logistic",185},
       [25]={"automation",101,"logistic",119},
       [26]={"automation",34,"logistic",81},
       [30]={"automation",55,"logistic",203},
       [35]={"automation",55,"logistic",367},
       [36]={"automation",46,"logistic",113},
       [38]={"logistic",77},
       [42]={"automation",84,"logistic",220},
       [46]={"automation",133,"logistic",369},
       [48]={"automation",68,"logistic",214},
       [49]={"automation",12,"logistic",56},
       [51]={"automation",98,"logistic",135},
       [63]={"automation",319,"logistic",831},
       [65]={"automation",59,"logistic",97},
       [68]={"military",122},
       [69]={"automation",103,"logistic",259},
       [70]={"automation",35,"logistic",112,"military",22},
       [72]={"automation",27,"logistic",81},
       [74]={"automation",106,"logistic",158},
       [77]={"automation",85,"logistic",194},
       [79]={"automation",61,"logistic",178,"military",106},
       [80]={"military",81},
       [83]={"automation",147,"logistic",329,"military",195},
       [86]={"automation",157,"logistic",278},
       [87]={"military",129},
       [89]={"automation",141,"logistic",150},
       [90]={"automation",38,"logistic",95,"military",172},
       [999]={"logistic",0,"military",0,"chemical",0}
    }
}

Public.detail_game_id[3444] = { ["Team"]="C4", ["Info"]="Burner green rush x20", ["Pack"]="pack_03", ["Versus"]="SteelAxe", ["Date"]="02 dec 21",
    ["Pattern"]={
       [14]={"logistic",11},
       [15]={"logistic",7},
       [19]={"logistic",100},
       [21]={"logistic",10},
       [22]={"logistic",95},
       [23]={"logistic",160},
       [24]={"logistic",106},
       [26]={"logistic",137},
       [29]={"logistic",1},
       [30]={"logistic",238},
       [33]={"logistic",48},
       [38]={"logistic",130},
       [999]={"logistic",100}
    }
}
Public.detail_game_id[3445] = { ["Team"]="SteelAxe", ["Info"]="Burner green rush x40", ["Pack"]="pack_03", ["Versus"]="C4", ["Date"]="02 dec 21",
    ["Pattern"]={
       [14]={"logistic",116},
       [15]={"logistic",92},
       [16]={"logistic",52},
       [17]={"logistic",131},
       [18]={"logistic",102},
       [20]={"logistic",107},
       [22]={"logistic",184},
       [23]={"logistic",187},
       [25]={"logistic",140},
       [28]={"logistic",498},
       [30]={"logistic",121},
       [31]={"logistic",143},
       [33]={"logistic",241},
       [36]={"logistic",794},
       [37]={"logistic",82},
       [38]={"logistic",466},
       [999]={"logistic",300}
    }
}

Public.detail_game_id[3567] = { ["Team"]="C4", ["Info"]="Green Rush", ["Pack"]="pack_01", ["Versus"]="Old Guard", ["Date"]="11 dec 21",
    ["Pattern"]={
       [16]={"logistic",121},
       [23]={"logistic",420},
       [27]={"logistic",209},
       [30]={"logistic",264},
       [31]={"logistic",154},
       [35]={"logistic",676},
       [39]={"logistic",834},
       [45]={"logistic",1686},
       [52]={"logistic",1811},
       [56]={"automation",1,"logistic",1194},
       [999]={"logistic",200}
    }
}
Public.detail_game_id[3568] = { ["Team"]="Old Guard", ["Info"]="Red into green rush", ["Pack"]="pack_01", ["Versus"]="C4", ["Date"]="11 dec 21",
    ["Pattern"]={
       [5]={"automation",12},
       [6]={"automation",160},
       [7]={"automation",70},
       [9]={"automation",76},
       [10]={"automation",40},
       [12]={"automation",37},
       [13]={"automation",51},
       [17]={"logistic",11},
       [18]={"logistic",29},
       [19]={"logistic",127},
       [20]={"logistic",102},
       [22]={"logistic",242},
       [25]={"automation",40,"logistic",431},
       [26]={"logistic",46},
       [27]={"automation",36,"logistic",104},
       [28]={"automation",13,"logistic",61},
       [30]={"automation",67,"logistic",340},
       [31]={"logistic",105},
       [32]={"automation",25,"logistic",41},
       [33]={"automation",10,"logistic",124},
       [34]={"automation",1,"logistic",214},
       [36]={"logistic",257},
       [38]={"logistic",215},
       [41]={"logistic",185},
       [44]={"automation",56,"logistic",369},
       [46]={"automation",26,"logistic",354},
       [49]={"logistic",330},
       [50]={"logistic",128},
       [52]={"automation",17,"logistic",121},
       [56]={"logistic",223},
       [999]={"automation",26,"logistic",200}
    }
}

Public.detail_game_id[3690] = { ["Team"]="Green Science", ["Info"]="Burner green rush x24", ["Pack"]="pack_03", ["Versus"]="Steelaxe Mafia", ["Date"]="09 dec 21",
    ["Pattern"]={
       [14]={"logistic",42},
       [16]={"logistic",59},
       [21]={"logistic",204},
       [22]={"automation",2,"logistic",77},
       [25]={"logistic",159},
       [26]={"logistic",76},
       [28]={"logistic",216},
       [36]={"logistic",542},
       [41]={"logistic",323},
       [43]={"logistic",106},
       [47]={"logistic",271},
       [48]={"logistic",202},
       [53]={"logistic",381},
       [54]={"automation",31,"logistic",67},
       [55]={"military",16},
       [999]={"logistic",150}
    }
}
Public.detail_game_id[3691] = { ["Team"]="Steelaxe Mafia", ["Info"]="Burner green rush x50", ["Pack"]="pack_03", ["Versus"]="Green Science", ["Date"]="09 dec 21",
    ["Pattern"]={
       [13]={"logistic",28},
       [15]={"logistic",112},
       [17]={"logistic",183},
       [19]={"logistic",203},
       [20]={"logistic",98},
       [21]={"logistic",5},
       [24]={"logistic",476},
       [25]={"logistic",139},
       [27]={"logistic",307},
       [29]={"logistic",576},
       [31]={"logistic",198},
       [33]={"logistic",355},
       [34]={"logistic",235},
       [35]={"logistic",174},
       [36]={"logistic",318},
       [38]={"logistic",235},
       [43]={"logistic",378},
       [44]={"logistic",438},
       [46]={"logistic",101},
       [47]={"logistic",6},
       [48]={"automation",184,"logistic",321},
       [50]={"logistic",858},
       [51]={"logistic",317},
       [53]={"logistic",425},
       [54]={"automation",188,"logistic",239},
       [55]={"logistic",359},
       [999]={"logistic",250}
    }
}

Public.detail_game_id[3813] = { ["Team"]="Mysticlutch", ["Info"]="The peninsula", ["Pack"]="pack_01", ["Versus"]="SteelAxe", ["Date"]="12 dec 21",
    ["Pattern"]={
       [12]={"automation",84,"logistic",51},
       [14]={"automation",36,"logistic",94},
       [16]={"automation",11,"logistic",43},
       [21]={"automation",34,"logistic",283},
       [22]={"logistic",35},
       [25]={"automation",13,"logistic",106},
       [27]={"automation",23,"logistic",121},
       [34]={"automation",21,"logistic",362},
       [40]={"military",40},
       [42]={"military",70},
       [43]={"automation",133,"logistic",493},
       [50]={"military",216},
       [52]={"automation",209,"logistic",630},
       [56]={"military",142},
       [59]={"automation",142,"logistic",373},
       [60]={"automation",36,"logistic",99,"military",57},
       [64]={"automation",21,"logistic",215,"military",126},
       [67]={"military",124},
       [68]={"automation",7,"logistic",135},
       [73]={"automation",28,"logistic",231,"military",280},
       [78]={"automation",7,"logistic",106,"military",223},
       [999]={"logistic",100,"military",50}
    }
}
Public.detail_game_id[3814] = { ["Team"]="SteelAxe", ["Info"]="The peninsula", ["Pack"]="pack_01", ["Versus"]="Mysticlutch", ["Date"]="12 dec 21",
    ["Pattern"]={
       [15]={"logistic",46},
       [34]={"automation",377,"logistic",136,"military",42},
       [39]={"automation",199,"logistic",148,"military",44},
       [47]={"automation",197,"logistic",125,"military",230},
       [51]={"automation",112},
       [55]={"automation",83,"logistic",45,"military",169},
       [70]={"military",278},
       [73]={"automation",433,"logistic",373,"military",234},
       [81]={"military",24},
       [999]={"logistic",50,"military",100}
    }
}

Public.detail_game_id[4059] = { ["Team"]="Steelaxe Mafia", ["Info"]="Burner green rush", ["Pack"]="pack_01", ["Versus"]="Old Guard", ["Date"]="19 dec 21",
    ["Pattern"]={
       [6]={"logistic",62},
       [7]={"logistic",47},
       [8]={"logistic",46},
       [9]={"logistic",38},
       [11]={"logistic",112},
       [12]={"logistic",85},
       [13]={"logistic",167},
       [14]={"logistic",124},
       [15]={"logistic",167},
       [16]={"logistic",106},
       [17]={"logistic",247},
       [18]={"logistic",143},
       [19]={"logistic",136},
       [22]={"automation",5,"logistic",373},
       [23]={"logistic",76},
       [24]={"logistic",216},
       [25]={"logistic",208},
       [26]={"logistic",222},
       [999]={"logistic",250}
    }
}
Public.detail_game_id[4060] = { ["Team"]="Old Guard", ["Info"]="Red into green rush", ["Pack"]="pack_01", ["Versus"]="Steelaxe Mafia", ["Date"]="19 dec 21",
    ["Pattern"]={
       [4]={"automation",34},
       [5]={"automation",46},
       [6]={"automation",58},
       [7]={"automation",69},
       [8]={"automation",38},
       [9]={"automation",17},
       [10]={"automation",31},
       [12]={"logistic",16},
       [14]={"logistic",74},
       [15]={"logistic",52},
       [16]={"logistic",70},
       [17]={"logistic",54},
       [18]={"logistic",77},
       [19]={"logistic",53},
       [20]={"logistic",71},
       [21]={"logistic",61},
       [22]={"logistic",66},
       [23]={"logistic",47},
       [24]={"automation",37,"logistic",37},
       [25]={"automation",31,"logistic",58},
       [999]={"automation",50,"logistic",100}
    }
}

Public.detail_game_id[4182] = { ["Team"]="Baguette", ["Info"]="Automated green", ["Pack"]="pack_01", ["Versus"]="Green Science", ["Date"]="16 dec 21",
    ["Pattern"]={
       [15]={"logistic",75},
       [18]={"logistic",62},
       [22]={"logistic",86},
       [25]={"logistic",41},
       [29]={"logistic",87},
       [33]={"logistic",60},
       [35]={"logistic",39},
       [37]={"logistic",265},
       [43]={"logistic",697},
       [46]={"logistic",283},
       [47]={"logistic",90},
       [50]={"automation",36,"logistic",460},
       [56]={"logistic",865},
       [58]={"logistic",231},
       [59]={"logistic",174},
       [61]={"logistic",665},
       [63]={"logistic",241},
       [64]={"logistic",199},
       [67]={"logistic",593},
       [69]={"logistic",359},
       [70]={"logistic",279},
       [74]={"logistic",779},
       [75]={"logistic",89},
       [76]={"logistic",391},
       [77]={"logistic",398},
       [79]={"logistic",423},
       [81]={"logistic",436},
       [999]={"logistic",200}
    }
}
Public.detail_game_id[4183] = { ["Team"]="Green Science", ["Info"]="Red into green rush", ["Pack"]="pack_01", ["Versus"]="Baguette", ["Date"]="16 dec 21",
    ["Pattern"]={
       [2]={"automation",26},
       [4]={"automation",18},
       [6]={"automation",164},
       [7]={"automation",153},
       [9]={"automation",309},
       [10]={"automation",254},
       [12]={"automation",521},
       [13]={"automation",275},
       [15]={"automation",336},
       [16]={"automation",321},
       [20]={"automation",1017},
       [24]={"automation",1127},
       [30]={"automation",836},
       [36]={"automation",82,"logistic",513},
       [44]={"logistic",1157},
       [61]={"logistic",2561},
       [67]={"logistic",704},
       [69]={"logistic",564},
       [73]={"logistic",760},
       [80]={"logistic",1217},
       [82]={"logistic",627},
       [999]={"logistic",300}
    }
}

Public.detail_game_id[4551] = { ["Team"]="Green Science", ["Info"]="Burner Green Rush x40(/48)", ["Pack"]="pack_03", ["Versus"]="SteelAxe", ["Date"]="15 dec 21",
    ["Pattern"]={
       [10]={"automation",11},
       [18]={"logistic",101},
       [23]={"logistic",134},
       [27]={"logistic",301},
       [38]={"logistic",510},
       [46]={"logistic",660},
       [54]={"logistic",1225},
       [999]={"logistic",200}
    }
}
Public.detail_game_id[4552] = { ["Team"]="SteelAxe", ["Info"]="Burner Green Rush x60", ["Pack"]="pack_03", ["Versus"]="Green Science", ["Date"]="15 dec 21",
    ["Pattern"]={
       [14]={"logistic",9},
       [16]={"logistic",46},
       [17]={"logistic",123},
       [20]={"logistic",217},
       [21]={"logistic",87},
       [23]={"logistic",375},
       [27]={"logistic",429},
       [29]={"logistic",143},
       [31]={"logistic",230},
       [32]={"logistic",418},
       [35]={"logistic",707},
       [38]={"automation",125,"logistic",797},
       [41]={"automation",92,"logistic",515},
       [43]={"logistic",734},
       [44]={"logistic",220},
       [45]={"automation",75,"logistic",368},
       [47]={"automation",53,"logistic",423},
       [50]={"logistic",735},
       [53]={"logistic",324},
       [54]={"logistic",570},
       [55]={"logistic",57},
       [999]={"logistic",250}
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
Public.list_teams ={["All"]="All"}
for gameId, pattern in pairs(Public.detail_game_id) do
	--Construct list of patterns
	table.insert(Public.list_game_id,gameId)
	--Find time of last sending (so time=[999] will be used after)
	local _last_time=0
	for _time,_ in pairs(pattern["Pattern"]) do
		if _time~=999 and _time>_last_time then _last_time=_time end
	end
	Public.detail_game_id[gameId]["Last"]=_last_time
	--Construct list of teams
	if not Public.list_teams[pattern["Team"]] then Public.list_teams[pattern["Team"]]=pattern["Team"] end
end
table.sort(Public.list_teams, function(a,b) return string.byte(a)<string.byte(b) end)
return Public