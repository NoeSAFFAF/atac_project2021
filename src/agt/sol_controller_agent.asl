/**
* A solution agent, it sends message to the adventurer agent to know which plan he has to execute in order
* to achieve the dungeon.
*/


!start.

+!start : true <-
	.print("I am the solution agent and will start communicating the solution to the dungeon adventurer agent after 5 sec, please comment me in the jcm file, create an agent in runtime, and use .send() to communicate with the dungeon agent if you want to look for the solution")
	.wait(5000)
	.send(dungeon_adventurer,achieve,investigate);
	.wait(2000)
	.send(dungeon_adventurer,achieve,take(silverKey));
	.wait(2000)
	.send(dungeon_adventurer,achieve,look_doors);
	.wait(2000)
	.send(dungeon_adventurer,achieve,move(door1_2));
	.wait(2000)
	.send(dungeon_adventurer,achieve,investigate);
	.wait(2000)
	.send(dungeon_adventurer,achieve,take(goldenKey));
	.wait(2000)
	.send(dungeon_adventurer,achieve,look_doors);
	.wait(2000)
	.send(dungeon_adventurer,achieve,move(door1_2));
	.wait(2000)
	.send(dungeon_adventurer,achieve,move(door1_3));
	.wait(2000)
	.send(dungeon_adventurer,achieve,look_doors);
	.wait(2000)
	.send(dungeon_adventurer,achieve,move(door3_4));
	.




{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }