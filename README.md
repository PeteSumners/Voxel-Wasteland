# Voxel-Wasteland
I'm working on a Godot project similar to this: https://www.youtube.com/watch?v=a1eP4xY3KXI

## Controls
WASD - move around

Space - jump

Right-click - throw grenades/use jetpack

F - build blocks

## Quirks
You can't strafe in midair

Voxel chunks are made up of a bunch of entities (instead of a single mesh with various textures). It was simpler to code that way, but performance isn't great at the moment. I'll fix it to use the Marching Cubes algorithm soon. 

Look around when you first spawn in. The character's in a kinda wonky direction. 

You should see a grey circle on the ground and a grey jetpack, too. You can pick up either, but I haven't added code to throw away the jetpack, so if you want to use the grenade, just pick it up first. Otherwise, Alt+F4 and restart the game to reset it. 

## Running the Windows Executable
You need the .exe and the .pck file in the same directory.

