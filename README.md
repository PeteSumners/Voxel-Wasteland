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
