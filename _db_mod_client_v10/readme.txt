///////////////////////////////////////////////////////////////////////////////////////////

                            Dodgeball mod

                    Created by Harbinger of Doom ( xfire: sgtderekt )


Feel free to use anything I created without asking permission, please just give me credit.

/////////////////////////////////////////////////////////////////////////////////////////////


Instructions to use the mod on a dedicated server

1. It is highly recommonded that you change the default music files, as they are empty. To change the music,
   select the desired .mp3 files that you want. Open the clientside .pk3 and go to sound/music. There
   you will find 12 different song files. Two of these files are for the main menu, the other songs are played in game.
   Replace all of the songs that you want, but it MUST be done in order by song name. Then, the lengths of the songs have 
   to be inserted into the db.cfg. This is done in seconds. Be careful when you do this, as it can be a confusing conversion.
   Leave any unused songs at length 0.Main menu song lengths do not need to be set. Please follow all copywrite laws.
   You are responsible for making sure everything you use is legal to distribute. Make sure you resave
   it as a pk3. Pakscape is a great tool to help do this, and is available at modsonline.com.



2. Take all of the files in the zip and put it into a new folder in the callOdfDuty directory in your
   server. DO NOT just put all of the files in main. It will put all of the files in main for the client.
   That will result in them failing pure checks.


3. If you have a redirect do the same thing as step 1 in the redirect. DO NOT put the .cfg or the server side file in
   the redirect. They should NOT receive either of these, especially the cfg. That will give them your rcon. 
   It is high recommomended that you use a redirect, as the download can be big.


4. Make sure the db.cfg is executed somewhere. Servers usually come with a default cfg file, often called
   "dedicaded.cfg". This would be a good place to execute the .cfg. There is a lot of other setup that needs
   to be done. This is dependent upon your server type and provider. The best thing to do is to take a working
   example and modify it so that it works. If you have trouble contact your server provider, or use the internet
   to help. Many server providers have forums. There is also many links on the internet on how to set up a server.


5. Make sure the server is set to run out of the new folder you created. The cvar to change this is "fs_game".


6. Run the server. It should work now. Have patience and use your resources. It is hard setting up servers,
   even when you write the code they run.


//////////////////////////////////////////////////////////////////////////

How to play dodgeball:

Dodgeball is a round-based, 5 v 5 gametype for COD 1.5. The game starts out with a warmup match. 
When that finshes, the game starts normal play. Each round begins with each team on opposite sides of the map, 
unable to move.There is a 10 second count down and the players are released. All players start unarmed, but 
there are balls in the middle of the court for them to pick up. Players rush to the middle to get 
balls and begin knocking out opponents.Opponents can be knocked out by taking a DIRECT hit with a ball, 
or by having there ball caught. Once players are  eliminated, they become spectators until next round. 
Players also CANNOT go to the opposite team's side, or will be knocked out. 
The last team to have players left wins the round.

The controls are simple. Movement is like normal cod while picking up balls and catching/blocking balls is 
done with [melee]. It does not matter where you are hit to catch or block a ball, but melee must be pressed
right before the ball hits.


/////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////

         Harbinger of Doom

/////////////////////////////////////////


