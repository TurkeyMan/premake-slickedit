--
-- Name:        slickedit/slickedit_workspace.lua
-- Purpose:     Generate a SlickEdit workspace.
-- Author:      Manu Evans
-- Created:     2015/09/12
-- Copyright:   (c) 2015 Manu Evans and the Premake project
--

	local p = premake
	local project = p.project
	local workspace = p.workspace
	local tree = p.tree
	local slickedit = p.modules.slickedit

	slickedit.workspace = {}
	local m = slickedit.workspace

--
-- Generate a SlickEdit workspace
--
	function m.generate(wks)
		p.utf8()

		-- Header
		_p('<!DOCTYPE Workspace SYSTEM "http://www.slickedit.com/dtd/vse/10.0/vpw.dtd">')

		local version = "10.0"
		_p('<Workspace Version="%s" VendorName="SlickEdit">', version)

		-- Project list
		_p(1, '<Projects>')

		local tr = workspace.grouptree(wks)
		tree.traverse(tr, {
			onleaf = function(n)
				local prj = n.project

				-- Build a relative path from the workspace file to the project file
				local prjpath = p.filename(prj, ".vpj")
				prjpath = path.translate(path.getrelative(prj.workspace.location, prjpath))

				_x(2, '<Project File="%s"/>', prjpath)
			end,

			onbranch = function(n)
				-- TODO: not sure what situation this appears...?
				-- premake5.lua emit's one of these for 'contrib', which is a top-level folder with the zip projects
			end,
		})
		_p(1, '</Projects>')

		-- Environment list
--		_p(1, '<Environment>')
--			_p(2, '<Set Name="VAR" Value="10"/>')
--		_p(1, '</Environment>')

		_p('</Workspace>')
	end
