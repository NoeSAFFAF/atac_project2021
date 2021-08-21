
/**
* This file describes the behavior of a adventurer agent in a dungeon. It uses the artifact
* LinkedDataFuSpider to navigate through resources on a linked-data platform. The platform
* used in apache Jena Fuseki with the root iri of our dungeon environment
* "http://localhost:3030/atacDungeon" and our agent starts at room1 (described as
* http://localhost:3030/atacDungeon?graph=room1). Through several actions defined as plans
* the agent can navigate through the dungeon and interact with its environment through
* CRUD requests made by the artifact. To understand how the artifact works, please look
* at the source code or at the example project.
*
* Each time the agent inspect a new room, look for doors, and inspect objects, it crawls
* triples of the thing in the linked data platform and add unary/binary predicates derived
* from the rdf triples.
*
* All available actions :
* - investigate (investigate the current room for any item in the room)
* - take(ITEM) (take an item that is in the room)
* - look_doors (look for all doors in the current room that connects to another room)
* - move(CONNECTION) (move through a door (which is a subclass of connection) and enter the new room)
*
* The plan check_goal checks regularly the current room and inform the user when he reaches the goal room (room4)
*/

//The IRI namespace of our dungeon environment
rootEnvUri("http://localhost:3030/atacDungeon?graph=").

!start.

+!start : true <-
	!init;
	.print("Wait for an action...")
    .


+!init : true <-
    //Create an LinkedDataFu artifact and focus on it
	!create_and_focus_ldfu;
	//Add ontologies necessary to describe things of the dungeon
	!addModel;
	//
	!startLocation(room1);
	!!check_goal(room4)
	.

+!addModel : true <-
	//register our dungeon model ontology saved in a local file
	register("model/dungeon.owl");
	.

+!startLocation(START_ROOM) : rootEnvUri(ROOT_ENV_IRI) <-
	-+currentRoom(START_ROOM);
	.concat(ROOT_ENV_IRI, START_ROOM, START_ROOM_IRI);
	// Fetch triples about the first room
	get(START_ROOM_IRI);
	.print("Starting room : ", START_ROOM);
	.
///////////////////////////////////
// All adventurer agents actions //
///////////////////////////////////

// The investigate plan searches for all items in the current room (C_ROOM),
// Look for all item it has, construct the IRI based on the item, and
// fetch all new triples through a sending GET request using the Linked-Data-Fu
// Spider extension.
+!investigate : currentRoom(C_ROOM) & rootEnvUri(ROOT_ENV_IRI) <-
	.concat("Investigating : ", C_ROOM, MSG);
	.print(MSG);
	//Look for all the items in the room
	for (hasItem(C_ROOM, ITEM)){
		.print("Found a ", ITEM, " !");
		.concat(ROOT_ENV_IRI, ITEM, ITEM_IRI);
		//Check if the triples has not already been crawled, and execute a GET
		//request through an external operation available in the Linked-Data-Fu
		//Spider extension.
		if (not key(ITEM_IRI)){
			get(ITEM_IRI);	
		}
	}
	.

// The take plan searches takes an Item in the current room and removes it by
// by sending a DELETE request
+!take(ITEM) : currentRoom(C_ROOM) & rootEnvUri(ROOT_ENV_IRI) <-
	//Check if the item is in the room
	if(hasItem(C_ROOM,ITEM)){
		//Creating an intern belief to state that the key is in our inventory
		.print("Taking from ", C_ROOM, " the item ", ITEM);
		+myInventory(ITEM);
		
		//Execute a DELETE request to remove the triple in room's IRI using the
		//the Linked-Data-Fu Spider extension.
		
		// Because currently passing unary/binary predicates istead of the triple
		// (rdf(_,_,_)) is not supported, the delete operation should not be used.
		//.concat(ROOT_ENV_IRI, ROOM, ROOM_IRI);
		//delete(ROOM_IRI, hasItem(C_ROOM,ITEM));
	} else {
		.print("The item is not available in this room")
	}
	.

// The look_doors plan searches for all the doors the room is connected to
// and extract data about those doors
+!look_doors : currentRoom(C_ROOM) & rootEnvUri(ROOT_ENV_IRI) <-
	.print("looking doors from : ", C_ROOM);
	for (hasConnection(C_ROOM, CONNECTION)){
		.concat(ROOT_ENV_IRI, CONNECTION, CONNECTION_IRI);
		if (not door(CONNECTION_IRI)){
			//Extract the data through an HTTP request
			get(CONNECTION_IRI);	
		}
		for(hasConnectedRoom(CONNECTION, ADJ_ROOM)){
			if (not (ADJ_ROOM = C_ROOM)){
				.print("There is a door called ", CONNECTION, " that leads to ",ADJ_ROOM);
			}
		}
	}
	.

// The move plan look at all the doors connected to the room to see if one matches
// the one passed in parameter, and for that door, it looks at all possible keys to
// open the door and check if one of them is in our inventory, if so, it "moves"
// by switching the current room and extract information about that room
+!move(CONNECTION) : currentRoom(C_ROOM) & rootEnvUri(ROOT_ENV_IRI) <-
	// Check if the door (connection) is valid)
	if (hasConnection(C_ROOM, CONNECTION) & hasConnectedRoom(CONNECTION, ADJ_ROOM) & not (C_ROOM = ADJ_ROOM)){
		//Check all the keys the door can interact with
		for(hasInteractibleKey(CONNECTION, KEY)){
			//Check if there is such a key in the inventory
			if (myInventory(KEY)){
				//Update the current room
				.print("You opened the door with the key ", KEY, " and moved to ", ADJ_ROOM);
				-+currentRoom(ADJ_ROOM);
				.concat(ROOT_ENV_IRI, ADJ_ROOM, ADJ_ROOM_IRI);
				if (not room(ADJ_ROOM_IRI)){
					//Extract the new room's data through a request
					get(ADJ_ROOM_IRI);
				}
			} else {
				.print("You need the key ", KEY, " to open this door");
			}
		}
	}
	.


// 
+!interact : interactObjects <-
	.print("But how should I interact")
	//Todo
	//Not needed but you can be imaginative :)
	.

//Check if the goal room has been reached every second
+!check_goal(GOAL_ROOM) : true <- 
	if (currentRoom(C_ROOM) & C_ROOM = GOAL_ROOM){
		.print("Congratz !!! You attained the objective");
	} else {
		.wait(1000)
		!!check_goal(GOAL_ROOM);
	}
	.


{ include("common.asl") }