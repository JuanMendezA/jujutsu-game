-- Punto de entrada del servidor.

local PlayerData = require(script.Parent.PlayerData)
local Combat = require(script.Parent.Combat)
local Curses = require(script.Parent.Curses)

PlayerData.Start()
Combat.Start()
Curses.Start()
