--
-- Name:        slickedit/slickedit.lua
-- Purpose:     Define the SlickEdit action(s).
-- Author:      Manu Evans
-- Created:     2015/09/12
-- Copyright:   (c) 2015 Manu Evans and the Premake project
--

	local p = premake

	p.modules.slickedit = {}
	p.modules.slickedit._VERSION = p._VERSION

	local slickedit = p.modules.slickedit
	local project = p.project


	function slickedit.cfgname(cfg)
		local cfgname = cfg.buildcfg
		if slickedit.workspace.multiplePlatforms then
			cfgname = string.format("%s|%s", cfg.platform, cfg.buildcfg)
		end
		return cfgname
	end

	function slickedit.esc(value)
		return value
	end

	function slickedit.generateWorkspace(wks)
		p.eol("\r\n")
		p.indent("\t")
		p.escaper(slickedit.esc)

		p.generate(wks, ".vpw", slickedit.workspace.generate)
	end

	function slickedit.generateProject(prj)
		p.eol("\r\n")
		p.indent("    ")
		p.escaper(slickedit.esc)

		if project.iscpp(prj) then
			p.generate(prj, ".vpj", slickedit.project.generate)
		end
	end

	function slickedit.cleanWorkspace(wks)
		p.clean.file(wks, wks.name .. ".vpw")
		p.clean.file(wks, wks.name .. ".vpwhist")
		p.clean.file(wks, wks.name .. ".vtg")
	end

	function slickedit.cleanProject(prj)
		p.clean.file(prj, prj.name .. ".vpj")
	end

	function slickedit.cleanTarget(prj)
		-- TODO..
	end


	include("_preload.lua")
	include("slickedit_workspace.lua")
	include("slickedit_cpp.lua")

	return slickedit
