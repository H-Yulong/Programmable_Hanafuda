return  
[[	
	//This is the standard (well, technically my favourite, so I'll call it standard) rule
	//of Hanafuda Koi-Koi, as well as a demonstration of features of Yaku-Language

	precheck shide = #groupof 4 >= 1 with score 3;
	precheck double_shide overwrites shide = #groupof 4 >= 2 with score 6;
	precheck board_four overwrites all = #groupof 4 >= 1 onboard with score restart;

	precheck order = shide, double_shide, board_four;

	yaku kasu = #kasu >= 10 accu
				with score #kasu - 9;

	yaku tan = #tan >= 5 accu 
			   with score #tan - 4;

	yaku tane = #tane >= 5 accu 
				with score #tane - 4;

	name hana = 9;
	name sake = 33;
	yaku hanami_sake = hana and sake 
						  with score 1;

	name tsuki = 29;
	yaku tsukimi_sake = tsuki and sake 
						   with score 1;

	name ino = 25;
	name shika = 37;
	name cho = 21;
	yaku inoshikacho = ino and shika and cho 
					   with score 6;
	
	yaku akatan = 2 and 6 and 10 
				  with score 6;
	
	yaku aotan = 22 and 34 and 38 
				 with score 6;

	name ame = 41;
	yaku sanko = #ko == 3 and not ame 
				 with score 5;

	yaku shiko overwrites sanko = #ko == 4 and not ame 
								  with score 8;

	yaku ameshiko overwrites sanko = #ko == 4 and ame 
									 with score 7;

	yaku goko overwrites shiko,ameshiko,sanko = #ko == 5 
										  with score 10;

	yaku tsukifuda = #month now == 4 with score 5;

	bonus koi = if win and #koi == 1 then score + 1
				elseif win and #koi == 2 then score + 2
				elseif win and #koi == 3 then score + 3
				elseif win and #koi == 4 then score * 2
				elseif win and #koi == 5 then score * 3
				elseif win and #koi == 6 then score * 5
				elseif win and #koi == 7 then score * 10;

	//bouns double_koi = if win and #koi > 0 then score * (2 ^ (#koi + #koi opgot));

	bonus hanami_koi = if win and hanami_sake and #koi > 0 then score + 2;

	bonus tsukimi_koi = if win and tsukimi_sake and #koi > 0 then score + 2;

	bonus oya = if draw and oya then score + 3;

	bonus order = hanami_koi,tsukimi_koi,koi;

]]
