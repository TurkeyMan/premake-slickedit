--
-- Name:        slickedit/_preload.lua
-- Purpose:     Define the SlickEdit action.
-- Author:      Manu Evans
-- Created:     2015/09/12
-- Copyright:   (c) 2015 Manu Evans and the Premake project
--

	local p = premake

	newaction
	{
		-- Metadata for the command line and help system

		trigger         = "slickedit",
		shortname       = "SlickEdit",
		description     = "Generate SlickEdit project files",

		-- The capabilities of this action

		valid_kinds     = { "ConsoleApp", "WindowedApp", "Makefile", "SharedLib", "StaticLib" },
		valid_languages = { "C", "C++", "D" },
		valid_tools     = {
		    cc = { "gcc", "clang", "msc" },
			dc = { "dmd", "gdc", "ldc" }
		},

		-- Solution and project generation logic

		onSolution = function(sln)
			p.modules.slickedit.generateWorkspace(sln)
		end,
		onProject = function(prj)
			p.modules.slickedit.generateProject(prj)
		end,

		onCleanSolution = function(sln)
			p.modules.slickedit.cleanWorkspace(sln)
		end,
		onCleanProject = function(prj)
			p.modules.slickedit.cleanProject(prj)
		end,
		onCleanTarget = function(prj)
			p.modules.slickedit.cleanTarget(prj)
		end,
	}


--
-- Decide when the full module should be loaded.
--

	return function(cfg)
		return (_ACTION == "slickedit")
	end
