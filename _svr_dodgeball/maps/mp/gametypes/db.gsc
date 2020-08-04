/*

File name:         db.gsc
Author:            Harbinger of Doom (DJT)
date:              3/4/2013

This is the file for the db gametype. This gametype is a round based 5v5 dodge ball match.
The game starts out with a warmup match. When that finshes, the game starts normal play.
Each round begins with each team on opposite sides of the map, unable to move.
There is a 10 second count down and the players are released. All players start unarmed, but there are balls
in the middle of the court for them to pick up. Players rush to the middle to get balls and begin knocking out opponents.
Opponents can be knocked out by taking a DIRECT hit with a ball, or by having there ball caught. Once players are 
eliminated, they become spectators until next round. Players also CANNOT go to the opposite team's side, or will
be knocked out. The last team to have players left wins the round.

Use melee to pick up, catch, and block balls. Melee must hit be hit right before a ball touches to catch it.
   
*/



main()
{
	spawnpointname = "mp_teamdeathmatch_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	
	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	
	
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;

	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	
	allowed[0] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);
		
	level.roundWinner = "allies";
	
	if(getCvar("scr_tdm_timelimit") == "")		// Time limit per map
		setCvar("scr_tdm_timelimit", "30");
	else if(getCvarFloat("scr_tdm_timelimit") > 1440)
		setCvar("scr_tdm_timelimit", "1440");
	level.timelimit = getCvarFloat("scr_tdm_timelimit");
	setCvar("ui_tdm_timelimit", level.timelimit);
	makeCvarServerInfo("ui_tdm_timelimit", "30");

	if(getCvar("scr_tdm_scorelimit") == "")		// Score limit per map DJT
		setCvar("scr_tdm_scorelimit", "100");
	level.scorelimit = getCvarInt("scr_tdm_scorelimit");
	setCvar("ui_tdm_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_tdm_scorelimit", "100");

	if(getCvar("scr_forcerespawn") == "")		// Force respawning
		setCvar("scr_forcerespawn", "0");
	
	if(getCvar("scr_teambalance") == "")		// Auto Team Balancing
		setCvar("scr_teambalance", "0");
	level.teambalance = getCvarInt("scr_teambalance");
	level.teambalancetimer = 0;
	
	killcam = getCvar("scr_killcam");
	if(killcam == "")				// Kill cam
		killcam = "1";
	setCvar("scr_killcam", killcam, true);
	level.killcam = getCvarInt("scr_killcam");
	
	if(getCvar("scr_drawfriend") == "")		// Draws a team icon over teammates
		setCvar("scr_drawfriend", "0");
	level.drawfriend = getCvarInt("scr_drawfriend");
	
	teamscorepenalty = getCvar("scr_teamscorepenalty");
	if(teamscorepenalty == "")			// Decrement teamscore for team kills and suicides
		teamscorepenalty = "0";
	setCvar("scr_teamscorepenalty", teamscorepenalty);

		

	if(!isDefined(game["state"]))
		game["state"] = "playing";

	level.mapended = false;
	level.healthqueue = [];
	level.healthqueuecurrent = 0;
	
	level.team["allies"] = 0;
	level.team["axis"] = 0;
	
	if(level.killcam >= 1)
		setarchive(true);
}

Callback_StartGameType()
{
		
	getTeamsForGame();
	
	spawnpointname = "mp_teamdeathmatch_intermission";
	level.nullSpawnPoint = getentarray(spawnpointname, "classname")[0];
	
	
	if(!isDefined(game["layoutimage"]))
		game["layoutimage"] = "default";
	layoutname = "levelshots/layouts/hud@layout_" + game["layoutimage"];
	precacheShader(layoutname);
	setCvar("scr_layoutimage", layoutname);
	makeCvarServerInfo("scr_layoutimage", "");
	mapstuff();
	
	
	game["menu_serverinfo"] = "serverinfo_" + getCvar("g_gametype");
	//game["menu_serverinfo"] = "serverinfo_tdm";DJT
	//game["menu_team"] = "team_" + game["allies"] + game["axis"];
	game["menu_team"] = "team_generic";
	game["menu_weapon_allies"] = "weapon_dodgeball";
	game["menu_weapon_axis"] = "weapon_dodgeball";
	game["menu_viewmap"] = "viewmap";
	game["menu_callvote"] = "callvote";
	game["menu_quickcommands"] = "quickcommands";
	game["menu_quickstatements"] = "quickstatements";
	game["menu_quickresponses"] = "quickresponses";

	precacheString(&"MPSCRIPT_PRESS_ACTIVATE_TO_RESPAWN");
	precacheString(&"MPSCRIPT_KILLCAM");
	precacheString(&"Warm-up");
	precacheString(&"^1You will join next round");
	precacheString(&"^2Made by Harbinger of Doom");
	precacheString(&"^1Knockout the other team");

	precacheMenu(game["menu_serverinfo"]);	
	precacheMenu(game["menu_team"]);
	precacheMenu(game["menu_weapon_allies"]);
	precacheMenu(game["menu_weapon_axis"]);
	precacheMenu(game["menu_viewmap"]);
	precacheMenu(game["menu_callvote"]);
	precacheMenu(game["menu_quickcommands"]);
	precacheMenu(game["menu_quickstatements"]);
	precacheMenu(game["menu_quickresponses"]);

	precacheShader("black");
	precacheShader("hudScoreboard_mp");
	precacheShader("gfx/hud/hud@mpflag_spectator.tga");
	precacheStatusIcon("gfx/hud/hud@status_dead.tga");
	precacheStatusIcon("gfx/hud/hud@status_connecting.tga");
	precacheItem("item_health");

	maps\mp\gametypes\_teams::modeltype();
	maps\mp\gametypes\_teams::precache();
	maps\mp\gametypes\_teams::scoreboard();
	maps\mp\gametypes\_teams::initGlobalCvars();
	maps\mp\gametypes\_teams::initWeaponCvars();
	maps\mp\gametypes\_teams::restrictPlacedWeapons();
	thread maps\mp\gametypes\_teams::updateGlobalCvars();
	thread maps\mp\gametypes\_teams::updateWeaponCvars();

	setClientNameMode("auto_change");
	
	/*Added by harb*/
	
	thread dodgeballConstants();
	precachemodel("xmodel/dodgeball");
	precachemodel("xmodel/afro");
	precachemodel("xmodel/aviators");
	precacheItem("dodgeball_mp");
	precacheItem("caught_mp");		
	precacheItem("_turn_on_downloads_then_reconnect_mp");
	
	/*Added by harb*/	

	thread startGame();
	thread addBotClients(); // For development testing
	thread updateGametypeCvars();
}

Callback_PlayerConnect()
{
	
	self.hadmessage = false;	
	self.spawnpoint = level.nullSpawnPoint;
	

	self setclientcvar("cl_allowDownload",1);

	self.statusicon = "gfx/hud/hud@status_connecting.tga";
	self waittill("begin");
	
	self setclientcvar("ui_alliesteam", "1. "+getPluralTeamName(game["allies"]));
	self setclientcvar("ui_axisteam", "2. "+getPluralTeamName(game["axis"]));
	
	

	self.statusicon = "";
	self.pers["teamTime"] = 0;
	
	iprintln(&"MPSCRIPT_CONNECTED", self);

	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("J;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");

	
	if(level.dbState == "playing")
		thread checkForRoundEnd();


	if(game["state"] == "intermission")
	{
		spawnIntermission();
		return;
	}
	
	level endon("intermission");

	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_weapontab", "1");

		if(self.pers["team"] == "allies")
		{
			self.sessionteam = "allies";
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
		}
		else
		{
			self.sessionteam = "axis";
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
		}
			
		if(isDefined(self.pers["weapon"]))
			spawnPlayer();
		else
		{
			spawnSpectator();

			if(self.pers["team"] == "allies")
				self openMenu(game["menu_weapon_allies"]);
			else
				self openMenu(game["menu_weapon_axis"]);
		}
	}
	else
	{
		self setClientCvar("g_scriptMainMenu", game["menu_team"]);
		self setClientCvar("ui_weapontab", "0");
		
		if(!isDefined(self.pers["skipserverinfo"]))
			self openMenu(game["menu_serverinfo"]);

		self.pers["team"] = "spectator";
		self.sessionteam = "spectator";

		spawnSpectator();
	}
	self setclientcvar("ui_rounds_to_win", "^1Rounds to win: " + getcvar("scr_db_rounds_to_win"));
	self thread musicHandler();	

	for(;;)
	{
		self waittill("menuresponse", menu, response);
		
		if(menu == game["menu_serverinfo"] && response == "close")
		{
			self.pers["skipserverinfo"] = true;
			self openMenu(game["menu_team"]);
		}

		if(response == "open" || response == "close")
			continue;

		if(menu == game["menu_team"])
		{
					
	
			switch(response)
			{
			case "allies":
			case "axis":
			case "autoassign":
				if(response == "autoassign")
				{
					numonteam["allies"] = 0;
					numonteam["axis"] = 0;

					players = getentarray("player", "classname");
					for(i = 0; i < players.size; i++)
					{
						player = players[i];
					
						if(!isDefined(player.pers["team"]) || player.pers["team"] == "spectator" || player == self)
							continue;
			
						numonteam[player.pers["team"]]++;
					}
					
					// if teams are equal return the team with the lowest score
					if(numonteam["allies"] == numonteam["axis"])
					{
						if(getTeamScore("allies") == getTeamScore("axis"))
						{
							teams[0] = "allies";
							teams[1] = "axis";
							response = teams[randomInt(2)];
						}
						else if(getTeamScore("allies") < getTeamScore("axis"))
							response = "allies";
						else
							response = "axis";
					}
					else if(numonteam["allies"] < numonteam["axis"])
						response = "allies";
					else
						response = "axis";
				}
				
				if(response == self.pers["team"] && self.sessionstate == "playing")
					break;

				if(response != self.pers["team"] && self.sessionstate == "playing")
					self suicide();

				self notify("end_respawn");

				self.pers["team"] = response;
				self.pers["teamTime"] = ((getTime() - level.starttime) / 1000);
				self.pers["weapon"] = undefined;
				self.pers["savedmodel"] = undefined;
				self.grenadecount = undefined;

				self setClientCvar("ui_weapontab", "1");

				if(self.pers["team"] == "allies")
				{
					self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
					self openMenu(game["menu_weapon_allies"]);
				}
				else
				{
					self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
					self openMenu(game["menu_weapon_axis"]);
				}
				break;

			case "spectator":
				if(self.pers["team"] != "spectator")
				{
					self.pers["team"] = "spectator";
					self.pers["teamTime"] = 0;
					self.pers["weapon"] = undefined;
					self.pers["savedmodel"] = undefined;
					self.grenadecount = undefined;
					
					self.sessionteam = "spectator";
					self setClientCvar("g_scriptMainMenu", game["menu_team"]);
					self setClientCvar("ui_weapontab", "0");
					spawnSpectator();
				}
				break;

			case "weapon":
				if(self.pers["team"] == "allies")
					self openMenu(game["menu_weapon_allies"]);
				else if(self.pers["team"] == "axis")
					self openMenu(game["menu_weapon_axis"]);
				break;
				
			case "viewmap":
				self openMenu(game["menu_viewmap"]);
				break;

			case "callvote":
				self openMenu(game["menu_callvote"]);
				break;
			}
		}		
		else if(menu == game["menu_weapon_allies"] || menu == game["menu_weapon_axis"])
		{
			if(response == "team")
			{
				self openMenu(game["menu_team"]);
				continue;
			}
			else if(response == "viewmap")
			{
				self openMenu(game["menu_viewmap"]);
				continue;
			}
			else if(response == "callvote")
			{
				self openMenu(game["menu_callvote"]);
				continue;
			}
			
			if(!isDefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis"))
				continue;

			weapon = self maps\mp\gametypes\_teams::restrict(response);

			if(weapon == "restricted")//DJT
			{
				self openMenu(menu);
				continue;
			}
			
			if(isDefined(self.pers["weapon"]) && self.pers["weapon"] == weapon)
				continue;
			
			if(!isDefined(self.pers["weapon"]))
			{
				self.pers["weapon"] = weapon;
				spawnPlayer();
				self thread printJoinedTeam(self.pers["team"]);
				checkForRoundEnd();
			}
			else
			{
				self.pers["weapon"] = weapon;

				weaponname = maps\mp\gametypes\_teams::getWeaponName(self.pers["weapon"]);
				
				if(maps\mp\gametypes\_teams::useAn(self.pers["weapon"]))
					self iprintln(&"MPSCRIPT_YOU_WILL_RESPAWN_WITH_AN", weaponname);
				else
					self iprintln(&"MPSCRIPT_YOU_WILL_RESPAWN_WITH_A", weaponname);
 			}
		}
		else if(menu == game["menu_viewmap"])
		{
			switch(response)
			{
			case "team":
				self openMenu(game["menu_team"]);
				break;
				
			case "weapon":
				if(self.pers["team"] == "allies")
					self openMenu(game["menu_weapon_allies"]);
				else if(self.pers["team"] == "axis")
					self openMenu(game["menu_weapon_axis"]);
				break;

			case "callvote":
				self openMenu(game["menu_callvote"]);
				break;
			}
		}
		else if(menu == game["menu_callvote"])
		{
			switch(response)
			{
			case "team":
				self openMenu(game["menu_team"]);
				break;
				
			case "weapon":
				if(self.pers["team"] == "allies")
					self openMenu(game["menu_weapon_allies"]);
				else if(self.pers["team"] == "axis")
					self openMenu(game["menu_weapon_axis"]);
				break;

			case "viewmap":
				self openMenu(game["menu_viewmap"]);
				break;
			}
		}
		else if(menu == game["menu_quickcommands"])
			maps\mp\gametypes\_teams::quickcommands(response);
		else if(menu == game["menu_quickstatements"])
			maps\mp\gametypes\_teams::quickstatements(response);
		else if(menu == game["menu_quickresponses"])
			maps\mp\gametypes\_teams::quickresponses(response);
	}
	
}

Callback_PlayerDisconnect()
{
	if(self getcurrentweapon() == "dodgeball_mp")
	{	
		self takeweapon("dodgeball_mp");
		self thread dropBall((randomInt(20)-10,randomInt(20)-10,randomInt(20)-10),self.origin +(0,0,60));
	}	

	

	iprintln(&"MPSCRIPT_DISCONNECTED", self);
	
	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("Q;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");
	if(level.dbState == "playing")
		thread checkForRoundEnd();
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc)
{
	

	//iprintlnbold("My origin" + self.origin);DJT
	//iprintlnbold("My angles" + self.angles);
	//iprintlnbold("vPoint" + vPoint);
	//iprintlnbold("vDir" + vDir);
	if(self == eAttacker )
		self thread throwBall( maps\mp\_utility::vectorScale((vPoint - self.origin - (0,0,65)),20) ,vPoint);

	return;


	if(self.sessionteam == "spectator")
		return;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
			if(level.friendlyfire == "0")
			{
				return;
			}
			else if(level.friendlyfire == "1")
			{
				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;
	
				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
			}
			else if(level.friendlyfire == "2")
			{
				eAttacker.friendlydamage = true;
		
				iDamage = iDamage * .5;
		
				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;
		
				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
				eAttacker.friendlydamage = undefined;
				
				friendly = true;
			}
			else if(level.friendlyfire == "3")
			{
				eAttacker.friendlydamage = true;
		
				iDamage = iDamage * .5;
		
				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
				eAttacker.friendlydamage = undefined;
				
				friendly = true;
			}
		}
		else
		{
			// Make sure at least one point of damage is done
			if(iDamage < 1)
				iDamage = 1;

			self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
		}
	}

	// Do debug print if it's enabled
	if(getCvarInt("g_debugDamage"))
	{
		println("client:" + self getEntityNumber() + " health:" + self.health +
			" damage:" + iDamage + " hitLoc:" + sHitLoc);
	}

	if(self.sessionstate != "dead")
	{
		lpselfnum = self getEntityNumber();
		lpselfname = self.name;
		lpselfteam = self.pers["team"];
		lpselfGuid = self getGuid();
		lpattackerteam = "";

		if(isPlayer(eAttacker))
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackGuid = eAttacker getGuid();
			lpattackname = eAttacker.name;
			lpattackerteam = eAttacker.pers["team"];
		}
		else
		{
			lpattacknum = -1;
			lpattackGuid = "";
			lpattackname = "";
			lpattackerteam = "world";
		}

		if(isDefined(friendly)) 
		{  
			lpattacknum = lpselfnum;
			lpattackname = lpselfname;
			lpattackGuid = lpselfGuid;
		}
		
		logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
	

}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc)
{
	self endon("spawned");
	
	self playsound("redsquare_whistle");	

	self.out = true; //this needs to be done incase of /kill	

	if(self getcurrentweapon() == "dodgeball_mp" && self getweaponslotammo("primary") == 1)
	{
		self  takeweapon("dodgeball_mp");
		self thread dropBall((randomInt(20)-10,randomInt(20)-10,randomInt(20)-10),self.origin +(0,0,60));
	}
	
	
	if(self.sessionteam == "spectator")
		return;

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";
		
	// send out an obituary message to all clients about the kill
	//obituary(self, attacker, sWeapon, sMeansOfDeath);
	
	self.sessionstate = "dead";
	self.statusicon = "gfx/hud/hud@status_dead.tga";
	self.headicon = "";
	if (!isdefined (self.autobalance))
		self.deaths++;

	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpselfguid = self getGuid();
	lpselfteam = self.pers["team"];
	lpattackerteam = "";

	attackerNum = -1;
	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			doKillcam = false;
			if (!isdefined (self.autobalance))
			{
				attacker.score--;
				
				if ( getCvar("scr_teamscorepenalty") )
				{
					// suicides should affect teamscore
					//teamscore = getTeamScore(attacker.pers["team"]);
					//teamscore--;
					//setTeamScore(attacker.pers["team"], teamscore);
				}
			}
			
			//if(isDefined(attacker.friendlydamage))
				//clientAnnouncement(attacker, &"MPSCRIPT_FRIENDLY_FIRE_WILL_NOT"); 
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

			if(self.pers["team"] == attacker.pers["team"]) // killed by a friendly
			{
				attacker.score--;
				
				if ( getCvar("scr_teamscorepenalty") )
				{
					// team kills should affect teamscore
					//teamscore = getTeamScore(attacker.pers["team"]);
					//teamscore--;
					//setTeamScore(attacker.pers["team"], teamscore);
				}
			}
			else
			{
				attacker.score++;

				//teamscore = getTeamScore(attacker.pers["team"]);
				//teamscore++;DJT
				//setTeamScore(attacker.pers["team"], teamscore);
			
				checkScoreLimit();
			}
		}

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;
		
		self.score--;

		lpattacknum = -1;
		lpattackname = "";
		lpattackguid = "";
		lpattackerteam = "world";
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended)
		return;

	// Make the player drop his weapon
	//self dropItem(self getcurrentweapon());
	
	// Make the player drop health
	//self dropHealth();
	self.autobalance = undefined;
	body = self cloneplayer();
	body thread killOnCleanUp();

	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(level.dbState == "playing")
		thread checkForRoundEnd();

	if((getCvarInt("scr_killcam") <= 0) || (getCvarInt("scr_forcerespawn") > 0))
		doKillcam = false;
	
	self thread respawn();
}

spawnPlayer()
{
	self notify("spawned");
	self notify("end_respawn");
	
	resettimeout();

		
	self spawnSpectator();
	
	if(level.dbstate != "warmup")
	{
		
		
		self.nextRoundText = newClientHudElem(self);
		self.nextRoundText.x = 320;
		self.nextRoundText.y =  0;
		self.nextRoundText.alignX = "center";
		self.nextRoundText.alignY = "top";	
		self.nextRoundText setText(&"^1You will join next round");		
		self.nextRoundText.fontScale = 2;
		
		do
		{
			currTeam = self.pers["team"];
			level waittill("bring in players");
		
		}while( self.spawnpoint == level.nullSpawnPoint  &&  self.pers["team"] != currTeam);		

			
		if(isDefined(self.nextRoundText))
			self.nextRoundText destroy();
	}
	else
		self warmupSpawn();
	
	if(self.pers["team"] == "spectator")
		return;
	
	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing"; 
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.friendlydamage = undefined;
	self.canCatch = true;	
	
	trace = bulletTrace( self.spawnpoint.origin + (0,0,10), self.spawnpoint.origin - (0,0,400), false, self );

	self spawn(trace["position"], self.spawnpoint.angles);
	wait .001;

	self.spawnpoint = level.nullSpawnPoint;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;
	
	if(!isDefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	//fix floating players
	self setorigin( trace["position"] );	

	if(level.dbState == "countdown")
		self thread lockPlayers();
	
	//fix floating players
	self setorigin( trace["position"] );

	self thread tiltHandler();
		
	self.hatModel = "xmodel/afro";	
	self attach(self.hatModel);
	self attach( "xmodel/aviators" );
	
	self.pers["weapon"] = "dodgeball_mp"; //this should allow people to go through weapon menu if change to spec
		
	
	if(!self.hadmessage)
		self thread connectMessages();
	self.hadmessage = true;

	//if(self.pers["team"] == "allies")
		//self setClientCvar("cg_objectiveText", &"^1Knockout the other team");
	//else if(self.pers["team"] == "axis")
		//self setClientCvar("cg_objectiveText", &"^1Knockout the other team");

	if(level.drawfriend)
	{
		if(self.pers["team"] == "allies")
		{
			self.headicon = game["headicon_allies"];
			self.headiconteam = "allies";
		}
		else
		{
			self.headicon = game["headicon_axis"];
			self.headiconteam = "axis";
		}
	}
	self.out = false;

	//sometimes does not delete
	if(isDefined(self.nextRoundText))
			self.nextRoundText destroy();
}

spawnSpectator(origin, angles)
{
	self notify("spawned");
	self notify("end_respawn");
	
	
	resettimeout();

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.friendlydamage = undefined;

	if(self.pers["team"] == "spectator")
	{	
		self.statusicon = "";
		self.spawnpoint = level.nullSpawnPoint;
	}
	if(isDefined(origin) && isDefined(angles))
		self spawn(origin, angles);
	else
	{
         	spawnpointname = "mp_teamdeathmatch_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	
		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}
	
	//self setClientCvar("cg_objectiveText", &"^1Knockout the other team");
}

spawnIntermission()
{
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	self.sessionstate = "intermission";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.friendlydamage = undefined;

	spawnpointname = "mp_teamdeathmatch_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	
	if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
}

respawn()
{
	
	
	self thread spawnPlayer();
}

waitForceRespawnTime()
{
	self endon("end_respawn");
	self endon("respawn");
	
	wait getCvarInt("scr_forcerespawn");
	self notify("respawn");
}

waitRespawnButton()
{
	self endon("end_respawn");
	self endon("respawn");
	
	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

	self.respawntext = newClientHudElem(self);
	self.respawntext.alignX = "center";
	self.respawntext.alignY = "middle";
	self.respawntext.x = 320;
	self.respawntext.y = 70;
	self.respawntext.archived = false;
	self.respawntext setText(&"MPSCRIPT_PRESS_ACTIVATE_TO_RESPAWN");

	thread removeRespawnText();
	thread waitRemoveRespawnText("end_respawn");
	thread waitRemoveRespawnText("respawn");

	while(self useButtonPressed() != true)
		wait .05;
	
	self notify("remove_respawntext");

	self notify("respawn");	
}

removeRespawnText()
{
	self waittill("remove_respawntext");

	if(isDefined(self.respawntext))
		self.respawntext destroy();
}

waitRemoveRespawnText(message)
{
	self endon("remove_respawntext");

	self waittill(message);
	self notify("remove_respawntext");
}

killcam(attackerNum, delay)
{
	self endon("spawned");

//	previousorigin = self.origin;
//	previousangles = self.angles;
	
	// killcam
	if(attackerNum < 0)
		return;

	self.sessionstate = "spectator";
	self.spectatorclient = attackerNum;
	self.archivetime = delay + 7;

	// wait till the next server frame to allow code a chance to update archivetime if it needs trimming
	wait 0.05;

	if(self.archivetime <= delay)
	{
		self.spectatorclient = -1;
		self.archivetime = 0;
		self.sessionstate = "dead";
	
		self thread respawn();
		return;
	}

	if(!isDefined(self.kc_topbar))
	{
		self.kc_topbar = newClientHudElem(self);
		self.kc_topbar.archived = false;
		self.kc_topbar.x = 0;
		self.kc_topbar.y = 0;
		self.kc_topbar.alpha = 0.5;
		self.kc_topbar setShader("black", 640, 112);
	}

	if(!isDefined(self.kc_bottombar))
	{
		self.kc_bottombar = newClientHudElem(self);
		self.kc_bottombar.archived = false;
		self.kc_bottombar.x = 0;
		self.kc_bottombar.y = 368;
		self.kc_bottombar.alpha = 0.5;
		self.kc_bottombar setShader("black", 640, 112);
	}

	if(!isDefined(self.kc_title))
	{
		self.kc_title = newClientHudElem(self);
		self.kc_title.archived = false;
		self.kc_title.x = 320;
		self.kc_title.y = 40;
		self.kc_title.alignX = "center";
		self.kc_title.alignY = "middle";
		self.kc_title.sort = 1; // force to draw after the bars
		self.kc_title.fontScale = 3.5;
	}
	self.kc_title setText(&"MPSCRIPT_KILLCAM");

	if(!isDefined(self.kc_skiptext))
	{
		self.kc_skiptext = newClientHudElem(self);
		self.kc_skiptext.archived = false;
		self.kc_skiptext.x = 320;
		self.kc_skiptext.y = 70;
		self.kc_skiptext.alignX = "center";
		self.kc_skiptext.alignY = "middle";
		self.kc_skiptext.sort = 1; // force to draw after the bars
	}
	self.kc_skiptext setText(&"MPSCRIPT_PRESS_ACTIVATE_TO_RESPAWN");

	if(!isDefined(self.kc_timer))
	{
		self.kc_timer = newClientHudElem(self);
		self.kc_timer.archived = false;
		self.kc_timer.x = 320;
		self.kc_timer.y = 428;
		self.kc_timer.alignX = "center";
		self.kc_timer.alignY = "middle";
		self.kc_timer.fontScale = 3.5;
		self.kc_timer.sort = 1;
	}
	self.kc_timer setTenthsTimer(self.archivetime - delay);

	self thread spawnedKillcamCleanup();
	self thread waitSkipKillcamButton();
	self thread waitKillcamTime();
	self waittill("end_killcam");

	self removeKillcamElements();

	self.spectatorclient = -1;
	self.archivetime = 0;
	self.sessionstate = "dead";

	//self thread spawnSpectator(previousorigin + (0, 0, 60), previousangles);
	self thread respawn();
}

waitKillcamTime()
{
	self endon("end_killcam");
	
	wait(self.archivetime - 0.05);
	self notify("end_killcam");
}

waitSkipKillcamButton()
{
	self endon("end_killcam");
	
	while(self useButtonPressed())
		wait .05;

	while(!(self useButtonPressed()))
		wait .05;
	
	self notify("end_killcam");	
}

removeKillcamElements()
{
	if(isDefined(self.kc_topbar))
		self.kc_topbar destroy();
	if(isDefined(self.kc_bottombar))
		self.kc_bottombar destroy();
	if(isDefined(self.kc_title))
		self.kc_title destroy();
	if(isDefined(self.kc_skiptext))
		self.kc_skiptext destroy();
	if(isDefined(self.kc_timer))
		self.kc_timer destroy();
}

spawnedKillcamCleanup()
{
	self endon("end_killcam");

	self waittill("spawned");
	self removeKillcamElements();
}



endMap()
{
	
	wait 5;
	game["state"] = "intermission";
	level notify("intermission");
	
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");
	
	if(alliedscore == axisscore)
	{
		winningteam = "tie";
		losingteam = "tie";
		text = "MPSCRIPT_THE_GAME_IS_A_TIE";
	}
	else if(alliedscore > axisscore)
	{
		winningteam = "allies";
		losingteam = "axis";
		text = &"MPSCRIPT_ALLIES_WIN";
	}
	else
	{
		winningteam = "axis";
		losingteam = "allies";
		text = &"MPSCRIPT_AXIS_WIN";
	}
	
	if((winningteam == "allies") || (winningteam == "axis"))
	{
		winners = "";
		losers = "";
	}
	
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if((winningteam == "allies") || (winningteam == "axis"))
		{
			lpGuid = player getGuid();
			if((isDefined(player.pers["team"])) && (player.pers["team"] == winningteam))
					winners = (winners + ";" + lpGuid + ";" + player.name);
			else if((isDefined(player.pers["team"])) && (player.pers["team"] == losingteam))
					losers = (losers + ";" + lpGuid + ";" + player.name);
		}
		player closeMenu();
		player setClientCvar("g_scriptMainMenu", "main");
		player setClientCvar("cg_objectiveText", text);
		player spawnIntermission();
	}
	
	if((winningteam == "allies") || (winningteam == "axis"))
	{
		logPrint("W;" + winningteam + winners + "\n");
		logPrint("L;" + losingteam + losers + "\n");
	}
	
	
	level notify("scoreboard");
	wait 10;
	exitLevel(false);
}

checkTimeLimit()
{
	if(level.timelimit <= 0)
		return;
	
	timepassed = (getTime() - level.starttime) / 1000;
	timepassed = timepassed / 60.0;
	
	if(timepassed < level.timelimit)
		return;
	
	if(level.mapended)
		return;
	level.mapended = true;

	iprintln(&"MPSCRIPT_TIME_LIMIT_REACHED");
	level thread endMap();
}

checkScoreLimit()
{
	if(level.scorelimit <= 0)
		return;
	
	if(getTeamScore("allies") < level.scorelimit && getTeamScore("axis") < level.scorelimit)
		return;

	if(level.mapended)
		return;
	level.mapended = true;

	iprintln(&"MPSCRIPT_SCORE_LIMIT_REACHED");
	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		timelimit = getCvarFloat("scr_tdm_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_tdm_timelimit", "1440");
			}
			
			level.timelimit = timelimit;
			setCvar("ui_tdm_timelimit", level.timelimit);
			level.starttime = getTime();
			
			if(level.timelimit > 0)
			{
				if(!isDefined(level.clock))
				{
					level.clock = newHudElem();
					level.clock.x = 320;
					level.clock.y = 440;
					level.clock.alignX = "center";
					level.clock.alignY = "middle";
					level.clock.font = "bigfixed";
				}
				level.clock setTimer(level.timelimit * 60);
			}
			else
			{
				if(isDefined(level.clock))
					level.clock destroy();
			}
			
			checkTimeLimit();
		}

		scorelimit = getCvarInt("scr_tdm_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_tdm_scorelimit", level.scorelimit);
		}
		checkScoreLimit();

		drawfriend = getCvarFloat("scr_drawfriend");
		if(level.drawfriend != drawfriend)
		{
			level.drawfriend = drawfriend;
			
			if(level.drawfriend)
			{
				// for all living players, show the appropriate headicon
				players = getentarray("player", "classname");
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					
					if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
					{
						if(player.pers["team"] == "allies")
						{
							player.headicon = game["headicon_allies"];
							player.headiconteam = "allies";
						}
						else
						{
							player.headicon = game["headicon_axis"];
							player.headiconteam = "axis";
						}
					}
				}
			}
			else
			{
				players = getentarray("player", "classname");
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					
					if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
						player.headicon = "";
				}
			}
		}

		killcam = getCvarInt("scr_killcam");
		if (level.killcam != killcam)
		{
			level.killcam = getCvarInt("scr_killcam");
			if(level.killcam >= 1)
				setarchive(true);
			else
				setarchive(false);
		}
		
		teambalance = getCvarInt("scr_teambalance");
		if (level.teambalance != teambalance)
		{
			level.teambalance = getCvarInt("scr_teambalance");
			if (level.teambalance > 0)
			{
				level thread maps\mp\gametypes\_teams::TeamBalance_Check();
				level.teambalancetimer = 0;
			}
		}
		
		
		
		if (level.teambalance > 0)
		{
			level.teambalancetimer++;
			if (level.teambalancetimer >= 60)
			{
				level thread maps\mp\gametypes\_teams::TeamBalance_Check();
				level.teambalancetimer = 0;
			}
		}
		
		wait 1;
	}
}

printJoinedTeam(team)
{
	if(team == "allies")
		iprintln(&"MPSCRIPT_JOINED_ALLIES", self);
	else if(team == "axis")
		iprintln(&"MPSCRIPT_JOINED_AXIS", self);
}

dropHealth()
{
	if(isDefined(level.healthqueue[level.healthqueuecurrent]))
		level.healthqueue[level.healthqueuecurrent] delete();
	
	level.healthqueue[level.healthqueuecurrent] = spawn("item_health", self.origin + (0, 0, 1));
	level.healthqueue[level.healthqueuecurrent].angles = (0, randomint(360), 0);

	level.healthqueuecurrent++;
	
	if(level.healthqueuecurrent >= 16)
		level.healthqueuecurrent = 0;
}

addBotClients()
{
	wait 5;
	
	for(;;)
	{
		if(getCvarInt("scr_numbots") > 0)
			break;
		wait 1;
	}
	
	iNumBots = getCvarInt("scr_numbots");
	for(i = 0; i < iNumBots; i++)
	{
		ent[i] = addtestclient();
		wait 0.5;

		if(isPlayer(ent[i]))
		{
			if(i & 1)
			{
				ent[i] notify("menuresponse", game["menu_team"], "axis");
				wait 0.5;
				ent[i] notify("menuresponse", game["menu_weapon_axis"], "kar98k_mp");
			}
			else
			{
				ent[i] notify("menuresponse", game["menu_team"], "allies");
				wait 0.5;
				ent[i] notify("menuresponse", game["menu_weapon_allies"], "springfield_mp");
			}
		}
	}
}






dodgeballConstants()
{
	if(getcvar("scr_db_gravity") == "")		
		setcvar("scr_db_gravity", 600); //positive value for gravity

	if(getcvar("scr_db_elasticity") == "")		
		setcvar("scr_db_elasticity", .8); //positive value for elasticity

	if(getcvar("scr_db_radius") == "")		
		setcvar("scr_db_radius", 4); 
	
	if(getcvar("scr_db_drag") == "")		
		setcvar("scr_db_drag", .9995); 

	if(getcvar("scr_db_warmup") == "")		
		setcvar("scr_db_warmup", 30);
	
	if(getcvar("scr_db_rounds_to_win") == "")		
		setcvar("scr_db_rounds_to_win", 5);


}


dodgeBallTest()
{
	level endon("intermisson");
	//add die and dc endons later
	
	
	/*
	Harbinger of Doom
	while(self.sessionstate == "playing")
	{
				
		if(self usebuttonpressed())
			self thread throwBall();	
			
		while(self usebuttonpressed()) //use trap
		{
							
			wait .05;
		}
			
		
		wait .05;
	}
	*/
	
}

throwBall(velocity,origin)
{
	
	
	ball =  spawn("script_model",origin);
	ball setmodel("xmodel/dodgeball");
	
	ball.velocityVector = velocity;
	
	ball.hot = true;
	ball.owner = self;
	ball thread doPhysics(getcvarfloat("scr_db_gravity"),getcvarfloat("scr_db_elasticity"),getcvarfloat("scr_db_radius"),getcvarfloat("scr_db_drag"));
	
	ball thread pickupThink();
	ball thread killOnCleanUp();

}

dropBall(velocity,origin)
{
	
	
	
	ball =  spawn("script_model",origin);
	ball setmodel("xmodel/dodgeball");
	
	ball.velocityVector = velocity;
	
	ball.hot = false;
	ball.owner = self;
	ball thread doPhysics(getcvarfloat("scr_db_gravity"),getcvarfloat("scr_db_elasticity"),getcvarfloat("scr_db_radius"),getcvarfloat("scr_db_drag"));
	
	ball thread pickupThink();
	ball thread killOnCleanUp();

}

placeBall(origin)
{
	
	
	
	ball =  spawn("script_model",origin);
	ball setmodel("xmodel/dodgeball");
	
	
	
	ball.hot = false;
	
	ball thread pickupThink();
	ball thread killOnCleanUp();

}

/*

Harbinger of Doom

This function will take care of physics for any object. 

This function should be called so that self is defined as the object i.e. self thread doPhysics(... and 
should be threaded

The object should have the following defined:

object.origin // starting point
object.velocityVector //inital velocity as a vector


This function will require the following parameters:


gravity: the desired gravity. This should be a positive number for downward gravity. 

elasticity: between 0 and 1, 0 is prefectly inelastic, 1 is perfectly elastic

radius: The approx. radius of the object

drag: Desired drag

To stop physics notify the object with "kill_physics" i.e. self notify("kill_physics");

*/

doPhysics(gravity,elasticity,radius,drag)
{
	thinkTime = .0005;	
	
	on = true;
	self endon("kill_physics");
	while(on)
	{
		
		
		effectiveTime = thinkTime;
		if( self checkAxisForCol( (0,0, -1 * radius -.00001) , 2) )		
		{	
			if(length(self.velocityVector) < .1) //on the ground and no speed
			{	
				on = false;			
				
			}
			self.accelerationVector = (0,0,0);
			self.velocityVector = (self.velocityVector[0],self.velocityVector[1],self.velocityVector[2] * .999);	
					

		}	
		else
			self.accelerationVector = (0,0,-1 * gravity);
		self.velocityVector += maps\mp\_utility::vectorScale(self.accelerationVector, thinkTime);
		self.velocityVector = maps\mp\_utility::vectorScale(self.velocityVector, drag);
		radiusVector = ( signOf(self.velocityVector[0]) * radius, signOf(self.velocityVector[1]) * radius ,signOf(self.velocityVector[2]) * radius );		
		
		collosionPoint = bulletTrace( self.origin,
			                      self.origin +maps\mp\_utility::vectorScale(self.velocityVector,effectiveTime) + radiusVector, 
                                              true, self );
		
			

		if(collosionPoint["fraction"] != 1 && on  )
		{
			if(length(self.velocityVector) > 30)
				self playsound("ball1");			
			if(self checkAxisForCol((self.velocityVector[0] * thinkTime + radiusVector[0],0,0),0))
			{	
				self.velocityVector = (-1*self.velocityVector[0] ,self.velocityVector[1],self.velocityVector[2]); 	
				
			}
			if(self checkAxisForCol((0,self.velocityVector[1] * thinkTime + radiusVector[1],0),1))
			{	
				self.velocityVector = (self.velocityVector[0],-1*self.velocityVector[1],self.velocityVector[2]);
				
			}
			if(self checkAxisForCol((0,0,self.velocityVector[2] * thinkTime + radiusVector[2]),2))
			{	
				self.velocityVector = (self.velocityVector[0],self.velocityVector[1],-1*self.velocityVector[2]);
				
			}			

			self.velocityVector = maps\mp\_utility::vectorScale(self.velocityVector, elasticity);
			effectiveTime = thinkTime - distance( self.origin, collosionPoint["position"]- radiusVector ) / length(self.velocityVector);
			self.origin = collosionPoint["position"] - radiusVector;
			
			if(isDefined(collosionPoint["entity"]))
			{	
				if(  self.owner.pers["team"] != collosionPoint["entity"].pers["team"] && collosionPoint["entity"].sessionstate == "playing" && self.hot && !collosionPoint["entity"].out && isPlayer(collosionPoint["entity"]))
				{	
					//iprintlnbold("collosionPoint[entity] meleebuttonpressed(): ^1" + collosionPoint["entity"] meleebuttonpressed()); 					
					//iprintlnbold("collosionPoint[entity].canCatch: ^1" + collosionPoint["entity"].canCatch );
					//iprintlnbold("collosionPoint[entity].sessionstate: ^1" + collosionPoint["entity"].sessionstate );
					//iprintlnbold("all: " +(collosionPoint["entity"] meleebuttonpressed() && collosionPoint["entity"].canCatch));

					if(collosionPoint["entity"] meleebuttonpressed() && collosionPoint["entity"].canCatch) //caught or blocked
					{
						if(collosionPoint["entity"] getweaponslotammo("primary") == 0)//caught
						{

							
							//self.owner  takeweapon("dodgeball_mp");
							//self.owner  thread dropBall((randomInt(20)-10,randomInt(20)-10,randomInt(20)-10),collosionPoint["entity"] .origin -(0,0,60));
							self.owner finishPlayerDamage(collosionPoint["entity"], collosionPoint["entity"], 1000, 0, "MOD_GRENADE_SPLASH", "caught_mp", self.origin, self.velocityVector, "TAG_NONE");
							self.owner.out = true;
							collosionPoint["entity"] giveWeapon("dodgeball_mp");
							collosionPoint["entity"] giveMaxAmmo("dodgeball_mp");
							collosionPoint["entity"] switchtoweapon("dodgeball_mp");
							
							
							thread tellAll(collosionPoint["entity"].name + "^1 has caught a ball thrown by ^7" + self.owner.name + "^1!");
							self notify("kill_physics");
							
							self delete();
						}
						else
							thread tellAll(collosionPoint["entity"].name + "^1 has blocked a ball thrown by ^7" + self.owner.name + "^1!");
					}				
					
					else
					{	
							 
						thread tellAll(self.owner.name + "^1 hit ^7" + collosionPoint["entity"].name + "^1!");	
						collosionPoint["entity"].out = true;
						collosionPoint["entity"] finishPlayerDamage(self.owner, self.owner, 1000, 0, "MOD_GRENADE_SPLASH", "dodgeball_mp", self.origin, self.velocityVector, "TAG_NONE");
					}
				}	
			}			

			
			
			self.hot = false;
		}

		
		self.origin += maps\mp\_utility::vectorScale(self.velocityVector,effectiveTime);
		self.angles += (self.velocityVector[0]*.01,0,self.velocityVector[1]*.01);
		
		
		wait thinkTime;
		
	}
}



checkAxisForCol(velocity,dim)
{
	
		
	trace = bulletTrace( self.origin,
			     self.origin + velocity, 
                             true, self );
	
	
	
	
	return (trace["fraction"] != 1);

}

signof(num)
{
	if(num >=0)
		return 1;
	else
		return -1;
}

pickupThink()
{
	pickedUp = false;
	while(!pickedUp)
	{
		
		players = getentarray("player","classname");
		if(isDefined(players)&& ! self.hot)
		{
			for(i=0;(i<players.size && !pickedUp);i++)
			{
				if(isDefined(players[i]))
				{
					if(distance(self.origin,players[i].origin) < 68 && !pickedUp && players[i] getweaponslotweapon("primary") == "none" && players[i] meleebuttonpressed() && players[i].sessionstate == "playing" && !self.hot )
					{
						
						players[i] giveWeapon("dodgeball_mp");
						players[i] giveMaxAmmo("dodgeball_mp");
						players[i] switchtoweapon("dodgeball_mp");
						self notify("kill_physics");
						wait .01;
						
						pickedUp = true;
					}
				}
			
				wait .04;
			}

		}
		wait .04;
	}
	self delete();

}

// Harbinger of Doom
// This handles the logic that stops people from being able to catch if the press melee for too long.
tiltHandler()
{
	self.canCatch = true;
	
	while(self.sessionstate == "playing")
	{

		self setclientcvar("cl_stance" ,0);
		if(self meleebuttonpressed())
		{
			//self iprintlnbold("pressed");
			for(i=0; (i<18 && self meleebuttonpressed());i++)
			{	
				wait .05;
				
			}
			self.canCatch = false;
			//self iprintlnbold("cannot catch");
			while(self meleebuttonpressed())
			{
				self setclientcvar("cl_stance" ,0);
				wait .25;
			}
			wait 1;
			
			//self iprintlnbold("can catch");
			self.canCatch = true;
		}
		wait .05;
	}

}

// Harbinger of Doom
// Registers all of the required components in the map
mapstuff() //this should only be called first time
{
	spawnpoints = getentarray("mp_teamdeathmatch_spawn", "classname");
	
	for(i=0; i<spawnpoints.size;i++)
		spawnpoints[i].hasPlayer = false;

	spawnpoints = getentarray("ballspawn", "targetname");
	
	for(i=0; i<spawnpoints.size;i++)//DJT
		placeBall(spawnpoints[i].origin);
	
	spawnpoints = getent("allies_trigger", "targetname");
	spawnpoints thread trigger_think("axis");

	spawnpoints = getent("axis_trigger", "targetname");
	spawnpoints thread trigger_think("allies");	

	return;
}


//allies_trigger
//axis_trigger

trigger_think(team)
{
	level endon("kill round");	

	while(1)
	{
		self waittill("trigger",player);
		if(player.pers["team"] == team && !player.out && player.sessionstate == "playing")
		{
			player.out = true;
			//player finishPlayerDamage(null,null , 1000, 0, "MOD_GRENADE_SPLASH", "colt_mp", self.origin, (0,0,0), "TAG_NONE");
			player suicide();
			tellAll(player.name + " ^1stepped onto the other team's side!");
		}
	}


}
startGame()
{
	
	//ambientPlay("dbmusic");
	level.starttime = getTime();
	level.dbState = "warmup";
	level.warmUp = getcvarint("scr_db_warmup");
	level.roundsToWin = getcvarint("scr_db_rounds_to_win");	
	

	level.wuclock = newHudElem();
	level.wuclock.x = 320;
	level.wuclock.y = 460;
	level.wuclock.alignX = "center";
	level.wuclock.alignY = "middle";
	level.wuclock.font = "bigfixed";
	level.wuclock setTimer(level.warmUp);	

	
	level.wutext = newHudElem();
	level.wutext.x = 320;
	level.wutext.y = 410;
	level.wutext.alignX = "center";
	level.wutext.alignY = "middle";
	level.wutext.fontScale = 1.5;
	level.wutext settext(&"Warm-up");	


	level.harbText = newHudElem();
	level.harbText.x = 0;
	level.harbText.y = 0;
	level.harbText.alignX = "left";
	level.harbText.alignY = "top";
	level.harbText.fontScale = .8;
	level.harbText settext(&"^2Made by Harbinger of Doom");	
	

	players =  getentarray("player","classname");
	for(i=0; i<level.warmUp ; i++)
	{
		wait 1;
		if(players.size == 0)
		{	
			i = 0;		
			level.wuclock setTimer(level.warmUp);	
		}
		players =  getentarray("player","classname");
	}
	
	level.wuclock destroy();	
	level.wutext destroy();
	wait 3;
	resetScores();
	thread smallMessages();
	do
	{
		
		level notify("kill round");
		level.dbState = "cleanup";
		roundCleanUp();
		setUpMapForRound();
		level.dbState = "countdown";
		handlePlayerSpawn();
		wait 6;
		level notify("bring in players");
		thread tellAll("^1Use melee to pick up balls");
		countDown();
		level notify("start round");
		level.dbState = "playing";
		if(anyoneIsPlaying())
			level waittill("round finished");
		//ambientStop();
		
		wait 2;		
	
	}while(getTeamScore(level.roundWinner) != level.roundsToWin);
	
	
	level.harbText destroy();
	level.mapended = true;
	level thread endMap();

}


// Harbinger of Doom
roundCleanUp()
{
	killEveryone();
	wait .5;
	level notify("clean up everything");
	wait .5;	

	return;
}



// Harbinger of Doom
// Kill everyone after a round
killEveryone()
{
	players = getentarray("player", "classname");
	for(i=0;i<players.size;i++)
	{
		if(players[i].sessionstate == "playing")
		{
			//players[i] finishPlayerDamage(null,null , 1000, 0, "MOD_GRENADE_SPLASH", null, self.origin, (0,0,0), "TAG_NONE");
			players[i] suicide();
			players[i].score++;
			players[i].deaths--;
		}
		//wait .1; //give it some time or everyone will be at the same point
	}
	return;
}

// Harbinger of Doom
killOnCleanUp()
{
	level waittill("clean up everything");
	self notify("Kill_physics");	//for balls
	wait .1;	
	self delete();

}

// Harbinger of Doom
setUpMapForRound()
{
	
	spawnpoints = getentarray("ballspawn", "targetname");
	
	for(i=0; i<spawnpoints.size;i++)
		placeBall(spawnpoints[i].origin);
	
	spawnpoints = getent("allies_trigger", "targetname");
	spawnpoints thread trigger_think("axis");

	spawnpoints = getent("axis_trigger", "targetname");
	spawnpoints thread trigger_think("allies");	

	return;
}

// Harbinger of Doom
// sets up the timer for count down before round
countDown()
{
	iprintlnbold("^1Round starting in 10 seconds!");
	level.cdownclock = newHudElem();
	level.cdownclock.x = 320;
	level.cdownclock.y = 250;
	level.cdownclock.alignX = "center";
	level.cdownclock.alignY = "middle";	
	level.cdownclock.font = "bigfixed";
	level.cdownclock.color = (1,0,0);
	level.cdownclock setTimer(10);	
	
	wait 10;
	thread playAll("redsquare_whistle");
	
	level.cdownclock destroy();
	
	return;


}

lockPlayers()
{
	
	anchor = spawn("script_origin",self.origin);
	self linkto(anchor);
	level waittill("start round");
	if(isPlayer(self)) //incase he disconnects djt
		self unlink(anchor);
	anchor delete();

}

checkForRoundEnd()
{
	if(level.dbState == "playing") 	
	{
		players = getentarray("player","classname");
		people["allies"] = 0;
		people["axis"] = 0;
		people["spectator"] = 0;
		for(i=0;i<players.size;i++)
			if(players[i].sessionstate == "playing")
			{	
				people[ players[i].pers["team"] ]++;
				level.roundWinner = players[i].pers["team"];
			}	

	
		if((people["axis"] ==0 || people["allies"] == 0) && level.dbState == "playing")
		{
			if(people["axis"] ==0 && people["allies"] == 0)	
			{
				level.roundWinner = "allies"; //does not matter it just needs to equal something
				iprintlnbold("^1Round was a draw");	
			}
			else
			{	
				teamscore = getTeamScore(level.roundWinner);
				teamscore++;
				setTeamScore(level.roundWinner, teamscore);
				iprintlnbold("^1The " + getPluralTeamName(game[level.roundWinner]) + "^1 have won the round");
				
			}
			level.dbState = "cleanup";
			level notify("round finished");
		}
	}
}


tellAll(message)
{
	players = getentarray("player", "classname");
	for(i=0;i<players.size;i++)
		players[i] iprintln(message);


}

playAll(sound)
{
	players = getentarray("player", "classname");
	for(i=0;i<players.size;i++)
		players[i] playsound(sound);


}




getTeamsForGame()
{
	switch(randomInt(6))
	{
	case 0:
		game["allies"] = "american";
		game["axis"] = "german";
		break;
	case 1:
		game["allies"] = "american";
		game["axis"] = "russian";
		break;
	case 2:
		game["allies"] = "american";
		game["axis"] = "british";
		break;
	case 3:
		game["allies"] = "british";
		game["axis"] = "german";
		break;
	case 4:
		game["allies"] = "british";
		game["axis"] = "russian";
		break;
	case 5:
		game["allies"] = "russian";
		game["axis"] = "german";
		break;
	default:
		game["allies"] = "american";
		game["axis"] = "german";
		break;

	}
	return;

}


handlePlayerSpawn()
{
	spawnpoints["allies"] = getentarray("allies", "targetname");
	spawnpoints["axis"] = getentarray("axis", "targetname");
	
	players = getentarray("player","classname");
	while(players.size == 0)
	{		
		wait .05;
		players = getentarray("player","classname");
	}
	spawnIndex["allies"] = 0;
	spawnIndex["axis"] = 0;
	
	for(i=0; i<players.size;i++)
	{	
				
		team = players[i].pers["team"];
		if(team == "allies" || team == "axis")
		{
			
			players[i].spawnpoint = spawnpoints[team][spawnIndex[team]];
			//spawnIndex[team]++;
			spawnIndex[team] = (spawnIndex[team] + 1) % spawnpoints[team].size;
			
		}	
	}
	
	return;


}


warmupSpawn()
{
	spawnpoints = getentarray(self.pers["team"], "targetname");
	self.spawnpoint = spawnpoints[randomInt(spawnpoints.size)];

}


// Harbinger of Doom
musicHandler()
{
	
	if( countNumberOfSongs() <= 0 )
		return;		


	self waittill("spawned");
	self endon("kill_music");
	self thread musicFixer();
	while(true)
	{
		song = randomInt( countNumberOfSongs() );
		self playlocalSound("dbmusic" + song);
		wait songTime(song);
		wait 3;
	}	

	
}

// Harbinger of Doom
musicHandlerNoWait()
{
	
	if( countNumberOfSongs() <= 0 )
		return;	

	//self waittill("spawned");
	self endon("kill_music");
	self thread musicFixer();
	while(true)
	{
		song = randomInt( countNumberOfSongs() );
		self playlocalSound("dbmusic" + song);
		wait songTime(song);
		wait 3;
	}	

	
}

// Harbinger of Doom
countNumberOfSongs()
{

	

	if( isDefined( level.numberOfSongs ) )
		return level.numberOfSongs;

	level.numberOfSongs = 0;

	while( isDefined( getcvarint( "scr_length_song" + ( level.numberOfSongs + 2 ) ) )
		 && getcvarint( "scr_length_song" + ( level.numberOfSongs + 2 ) ) > 0 )
		level.numberOfSongs++;

	return level.numberOfSongs;

}

// Harbinger of Doom
songTime(song)
{
	
	return getcvarint( "scr_length_song" + ( song + 1 ) );
	
}

// Harbinger of Doom
// Handles problem where music would stop when people went to main menu
musicFixer()
{
	
	menu = "blarg";
	response = "blarg";
	while( response != "openedMain") 	
	{
		
		
		self waittill("menuresponse", menu, response);
		//self iprintlnbold( menu + " " + response );
		
	}
	self notify("kill_music");
	while(response != "close")
	{	
		self waittill("menuresponse", menu, response);
		//self iprintlnbold( menu + " " + response );
		
	}
	self thread musicHandlerNoWait();
		
}

// Harbinger of Doom
// Is anyone on the server
anyoneIsPlaying()
{
	players = getentarray("player","classname");
	for(i=0;i<players.size;i++)
		if(players[i].sessionstate == "playing")
			return true;
	
	return false;


}

// Harbinger of Doom
// Resets kills and deaths after the warmup
resetScores()
{

	players = getentarray("player","classname");
	for(i=0;i<players.size;i++)
	{
		players[i].score = 0;
		players[i].deaths= 0;

	}
}

// Harbinger of Doom
smallMessages()
{

	i = 0;
	while(getcvar("scr_db_small_messages" + i) != "")
	{
		
		messages[i] = getcvar("scr_db_small_messages" + i);
		i++;

	}
	h=0;
	while(isDefined(messages))
	{
		wait 30;
		thread tellAll(messages[h]);
		h = (h+1)%i;

	}
}



// Harbinger of Doom
connectMessages()
{
	i = 0;
	while(getcvar("scr_db_connect_messages" + i) != "")
	{
		
		messages[i] = getcvar("scr_db_connect_messages" + i);
		i++;

	}
	for(h=0;h<i;h++)
	{
		self iprintlnbold(messages[h]);
		wait 2;
	}
}

// Harbinger of Doom
// Gets the team name in the correct form for printing to the screen
getPluralTeamName( team )
{

	switch(team)
	{
	case "american":
		return "Americans";
	case "british":
		return "British";
	case "russian":
		return "Russians";
	case "german":
		return "Germans";
	}
	return "Unknown team";

}


