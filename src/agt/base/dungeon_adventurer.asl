
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

!start.

+!start : true <-
	!init;
	.print("Wait for an action...")
    .


+!init : true <-
    //Create an LinkedDataFu artifact and focus on it
	!create_and_focus_ldfu;
	//Create an artifact to add a random functionality
	!create_and_focus_itemRandomizer
	//Add ontologies necessary to describe things of the dungeon
	!addModel;
	//Start to a location and get the data from that room
	!startLocation;
	!stepCycle;
	.

+!addModel : true <-
	//register our dungeon model ontology saved in a local file
	register("model/dungeon.owl");
	.

+!startLocation : rootEnvUri(ROOT_ENV_IRI) & start(START_ROOM) <-
	-+currentRoom(START_ROOM);
	.concat(ROOT_ENV_IRI, START_ROOM,START_ROOM_IRI);
	// Fetch triples about the first room
	!getPlan(START_ROOM_IRI);
	+hasBeenVisited(START_ROOM);
	.print("Starting room : ", START_ROOM);
.

+!getPlan(IRI) : true <-
    .concat(IRI,"/",N_IRI);
    get(N_IRI);
.

///////////////////////////////////
////////// Actions Plans //////////
///////////////////////////////////

// The investigate plan searches for all items in the current room (C_ROOM),
// Look for all item it has, construct the IRI based on the item, and
// fetch all new triples through a GET request using the Linked Data-Fu
// Spider extension.
+!investigate : currentRoom(C_ROOM) & rootEnvUri(ROOT_ENV_IRI) & not hasBeenInvested(C_ROOM) <-
	.print("Investigating : ", C_ROOM);
	//Look for all the items in the room
	for (hasItem(C_ROOM, ITEM)){
		.print("Found a ", ITEM, " !");
		.concat(ROOT_ENV_IRI, ITEM, ITEM_IRI);
		//Check if the triples has not already been crawled, and execute a GET
		//request through an external operation available in the Linked Data-Fu
		//Spider extension.
		if (not item(ITEM_IRI)){
			!getPlan(ITEM_IRI);
		}
	}
	+hasBeenInvested(C_ROOM);
	.

// The take plan searches takes an Item in the current room and removes it by
// by sending a DELETE request
+!take(ITEM) : currentRoom(C_ROOM) & rootEnvUri(ROOT_ENV_IRI) & not hasItemTaken(ITEM) <-
    .print("Attempting to take the item : ", ITEM, " : ", C_ROOM);
	//Check if the item is in the room

	if (hasItem(C_ROOM,ITEM)){
		//Creating an intern belief to state that the key is in our inventory
		.print("Taking from ", C_ROOM, " the item ", ITEM);
		+myInventory(ITEM);
		+hasItemTaken(ITEM);
		
		//Execute a DELETE request to remove the triple in room's IRI using the
		//the Linked-Data-Fu Spider extension.
		//Because currently passing unary/binary predicates instead of the triple
		//(rdf(_,_,_)) is not supported, the delete operation should not be used.
		//.concat(ROOT_ENV_IRI, ROOM, ROOM_IRI);
		//delete(ROOM_IRI, hasItem(C_ROOM,ITEM));
	} else {
		.print("The item is not available in this room")
	}
	.

// The look_doors plan searches for all the doors the room is connected to
// and extract data about those doors
+!look_doors : currentRoom(C_ROOM) & rootEnvUri(ROOT_ENV_IRI) & not hasLookedDoors(C_ROOM) <-
	.print("looking doors from : ", C_ROOM);
	for (hasConnection(C_ROOM, CONNECTION)){
		.concat(ROOT_ENV_IRI, CONNECTION, CONNECTION_IRI);
		if (not door(CONNECTION_IRI)){
			//Extract the data through an HTTP request
			!getPlan(CONNECTION_IRI);
		}
		for(hasConnectedRoom(CONNECTION, ADJ_ROOM)){
			if (not (ADJ_ROOM = C_ROOM)){
				.print("There is a door called ", CONNECTION, " that leads to ",ADJ_ROOM);
			}
		}
	}
	+hasLookedDoors(C_ROOM);
	.

// The move plan look at all the doors connected to the room to see if one matches
// the one passed in parameter, and for that door, it looks at all possible keys to
// open the door and check if one of them is in our inventory, if so, it "moves"
// by switching the current room and extract information about that room
+!move(CONNECTION) : currentRoom(C_ROOM) & rootEnvUri(ROOT_ENV_IRI) <-
	// Check if the door (connection) is valid)
	if (hasConnection(C_ROOM, CONNECTION) & hasConnectedRoom(CONNECTION, ADJ_ROOM) & needsKey(CONNECTION,KEYBOOL) & not (C_ROOM = ADJ_ROOM)){
	    .print("Attempting to move to : ", ADJ_ROOM, " with : ", CONNECTION);
	    if (KEYBOOL == "true"){
    		//Check all the keys the door can interact with
    		for(hasInteractibleKey(CONNECTION, KEY)){
    			//Check if there is such a key in the inventory
    			if (myInventory(KEY)){
    				//Update the current room
    				.print("You opened the door with the key ", KEY, " and moved to ", ADJ_ROOM);
    				-+currentRoom(ADJ_ROOM);
    				.concat(ROOT_ENV_IRI, ADJ_ROOM, ADJ_ROOM_IRI);
    				if (not room(ADJ_ROOM_IRI) & not hasBeenVisited(ADJ_ROOM_IRI)){
    					//Extract the new room's data through a request
    					!getPlan(ADJ_ROOM_IRI);
    					+hasBeenVisited(ADJ_ROOM_IRI);
    				}
    			} else {
    				.print("You need the key : ", KEY, " to open this door");
    			}
    		}
	    } else {
	        .print("You opened the door and moved to ", ADJ_ROOM);
            -+currentRoom(ADJ_ROOM);
            .concat(ROOT_ENV_IRI, ADJ_ROOM, ADJ_ROOM_IRI);
            if (not room(ADJ_ROOM_IRI)){
                //Extract the new room's data through a request
                !getPlan(ADJ_ROOM_IRI);
            }
	    }
	}
.

////////////////////////////////
//////// Cycling Plan //////////
////////////////////////////////

// Cycle Rounds between events like checking goals and action cycle
+!stepCycle : goal(GOAL_ROOM) <-
    if (currentRoom(C_ROOM) & C_ROOM = GOAL_ROOM){
    	.print("Congratz !!! You attained the objective");
    } else {
        !actionCycle;
    }
.

// Action cycle : A decision-making plan including all 4 actions.
// They are executed in the following sequential order :
// - If the room has not been investigated, investigate it
// - If the room has not been observed for new doors, look for new doors
// - If there is an item to take in the room : take it (randomly if multiple items)
// - If there is are doors connected to new room : move to it (randomly if multiple options)
+!actionCycle : true <-
    .wait(2000);
    if (currentRoom(C_ROOM) & not hasBeenInvested(C_ROOM)){
        !investigate;
    } elif (currentRoom(C_ROOM) & not hasLookedDoors(C_ROOM)){
        !look_doors;
    } elif (currentRoom(A) & hasItem(A,B) & not hasItemTaken(B)) {
        for (currentRoom(C_ROOM) & hasItem(C_ROOM,ITEM) & not hasItemTaken(ITEM) & not mapItemInteger(_,ITEM)){
            // A trick to have an item selected randomly simulating a hashmap
            addInteger(I);
            +mapItemInteger(I,ITEM);
        }
        pickRandomInteger(RANDOM_I);
        if (mapItemInteger(RANDOM_I,R_ITEM)){
            !take(R_ITEM);
        }
        .abolish(mapItemInteger(_,_));

    } elif (currentRoom(A) & hasConnection(A, B) & hasConnectedRoom(B, C) & needsKey(B,D) & not (A = C)) {
        for (currentRoom(C_ROOM) & hasConnection(C_ROOM, CONNECTION) & hasConnectedRoom(CONNECTION, ADJ_ROOM) & needsKey(CONNECTION,KEYBOOL) & not (C_ROOM = ADJ_ROOM) & not mapItemInteger(_,CONNECTION)){
            // Same trick
            addInteger(I);
            +mapItemInteger(I,CONNECTION);
            //.print(I, " : ",CONNECTION);
        }
        pickRandomInteger(RANDOM_I);
        if (mapItemInteger(RANDOM_I,R_CONNECTION)){
            !move(R_CONNECTION);
        }
        .abolish(mapItemInteger(_,_));

    }
    !stepCycle;
.

//Check if the goal room has been reached every second (only case non-autonomous)
+!check_goal(GOAL_ROOM) : true <- 
	if (currentRoom(C_ROOM) & C_ROOM = GOAL_ROOM){
		.print("Congratz !!! You attained the objective");
	} else {
		.wait(1000)
		!!check_goal(GOAL_ROOM);
	}
	.

////////////////////////////////
//////// Extra (unused) ////////
////////////////////////////////


+!interact : interactObjects <-
	.print("But how should I interact")
	//Todo
	//Not needed but you can be imaginative :)
	.


{ include("common.asl") }