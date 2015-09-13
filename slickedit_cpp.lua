--
-- Name:        slickedit/slickedit_cpp.lua
-- Purpose:     Generate a SlickEdit C/C++ project file.
-- Author:      Manu Evans
-- Created:     2015/09/12
-- Copyright:   (c) 2015 Manu Evans and the Premake project
--

	local p = premake
	local tree = p.tree
	local project = p.project
	local config = p.config
	local slickedit = p.modules.slickedit

	slickedit.project = {}
	local m = slickedit.project
	m.elements = {}


	function slickedit.getLinks(cfg)
		-- System libraries are undecorated, add the required extension
		return config.getlinks(cfg, "system", "fullpath")
	end

	function slickedit.getSiblingLinks(cfg)
		-- If we need sibling projects to be listed explicitly, add them on
		return config.getlinks(cfg, "siblings", "fullpath")
	end


	function m.quote_string(s)
		if string.find(s, '"') then
			return "'" .. s .. "'"
		else
			return '"' .. s .. '"'
		end
	end

	function m.emit_element(depth, element, options, optionsKeys, close)
		-- sort options into order
		local values = {}
		local count = 0
		for i, el in ipairs(optionsKeys) do
			for opt, val in pairs(options) do
				if string.lower(el) == string.lower(opt) then
					count = count + 1
					values[count] = { el, m.quote_string(val) }
				end
			end
		end

		-- emit options
		if count == 0 then
			_p(depth, '<%s%s', element, iif(close == true, "/>", ">"))
		else
			if count == 1 then
				_p(depth, '<%s %s=%s%s', element, values[1][1], values[1][2], iif(close == true, "/>", ">"))
			else
				_p(depth, '<%s', element)
				for i = 1, count do
					_x(depth + 1, "%s=%s%s", values[i][1], values[i][2], iif(i == count, iif(close == true, "/>", ">"), ""))
				end
			end
		end
	end


-- Menu

	m.elements.menu = function(cfg)
		return {
			m.compile,
			m.link,
			m.build,
			m.rebuild,
			m.debug,
			m.execute,
			m.dash,
			m.coptions,
		}
	end

	function m.menu(cfg, toolset, toolinfo)
		_p(2, '<Menu>')

		p.callArray(m.elements.menu, cfg, toolset, toolinfo)

		_p(2, '</Menu>')
	end

	m.target_elements = {
		"Name",
		"MenuCaption",
		"ShowOnMenu",
		"Dialog",
		"BuildFirst",
		"CaptureOutputWith",
		"Deletable",
		"OutputExts",
		"SaveOption",
		"RunFromDir",
		"ClearProcessBuffer",
		"Verbose",
		"Beep",
	}
	m.exec_elements = {
		"CmdLine",
		"OtherOptions",
		"Type",
	}
	function m.emit_target(options, exec)
		m.emit_element(3, "Target", options, m.target_elements)
		m.emit_element(4, "Exec", exec or {}, m.exec_elements, true)
		_p(3, '</Target>')
	end

	function m.compile(cfg, toolset, toolinfo)
		local options = {
			name="Compile",
			menuCaption="&amp;Compile",
			dialog="_gnuc_options_form Compile",
			captureOutputWith="ProcessBuffer",
			deletable="0",
			outputExts="*.o",
			saveOption="SaveCurrent",
			runFromDir="%rw",
		}
		local exec = {}

		-- build command line
		local tool = toolset.gettoolname({gccprefix=""}, iif(cfg.language == "C", "cc", "cxx"))
		exec.cmdLine = tool .. ' -c %xup ' .. iif(toolinfo.tool == "msc", '%defs ', '%defd ')

		-- compile flags
		local cppFlags = toolset.getcppflags(cfg)
		local cFlags = toolset.getcflags(cfg)
		local cxxFlags = {}
		if cfg.language ~= "C" then
			cxxFlags = toolset.getcxxflags(cfg)
		end

		local allFlags = table.join(cppFlags, cFlags, cxxFlags)
		exec.cmdLine = exec.cmdLine .. table.concat(allFlags, " ")

		-- additional build options
		if #cfg.buildoptions > 0 then
			exec.otherOptions = table.concat(cfg.buildoptions, " ")
			exec.cmdLine = exec.cmdLine .. ' %~other'
		end

		-- output and source file
		exec.cmdLine = exec.cmdLine .. ' -o "%bd%n%oe" %i "%f"'

		m.emit_target(options, exec)
	end

	function m.link(cfg, toolset, toolinfo)
		local options = {
			name="Link",
			menuCaption="&amp;Link",
			showOnMenu="Never",
			dialog="_gnuc_options_form Link",
			captureOutputWith="ProcessBuffer",
			deletable="0",
			saveOption="SaveCurrent",
			runFromDir="%rw",
		}
		local exec = { cmdLine = "" }

		if cfg.kind == premake.STATICLIB then
			if cfg.architecture == premake.UNIVERSAL then
				exec.cmdLine = 'libtool %xup -o "%o" %f'
			else
				local tool = toolset.gettoolname({gccprefix=""}, "ar")
				exec.cmdLine = tool .. ' -rs %xup "%o" %f'  -- TODO CHECK THAT THIS IS CORRECT? should be -rcs?
--				exec.cmdLine = tool .. ' -rcs %xup "%o" %f'
			end
		else
			-- build command line
			local tool = toolset.gettoolname({gccprefix=""}, iif(cfg.language == "C", "cc", "cxx"))
			exec.cmdLine = tool .. ' %xup '

			-- compile flags
			local ldFlags = toolset.getldflags(cfg)
			exec.cmdLine = exec.cmdLine .. table.concat(ldFlags, " ")

			-- additional build options
			if #cfg.linkoptions > 0 then
				exec.otherOptions = table.concat(cfg.linkoptions, " ")
				exec.cmdLine = exec.cmdLine .. ' %~other'
			end

			-- TODO: lib paths???

			-- output and source file
			exec.cmdLine = exec.cmdLine .. ' -o "%o" %objs %libs'
		end

		m.emit_target(options, exec)
	end

	function m.build(cfg)
		local options = {
			name="Build",
			menuCaption="&amp;Build",
			dialog="_gnuc_options_form Compile",
			captureOutputWith="ProcessBuffer",
			deletable="0",
			saveOption="SaveWorkspaceFiles",
			runFromDir="%rw",
		}

		-- HACK: clear before each build...
		options.clearProcessBuffer = "1"

		local exec = { cmdLine = '"%(VSLICKBIN1)vsbuild" "%w" "%r" -t build' }
		m.emit_target(options, exec)
	end

	function m.rebuild(cfg)
		local options = {
			name="Rebuild",
			menuCaption="&amp;Rebuild",
			dialog="_gnuc_options_form Compile",
			captureOutputWith="ProcessBuffer",
			deletable="0",
			saveOption="SaveWorkspaceFiles",
			runFromDir="%rw",
		}
		local exec = { cmdLine = '"%(VSLICKBIN1)vsbuild" "%w" "%r" -t rebuild' }
		m.emit_target(options, exec)
	end

	function m.debug(cfg)
		local options = {
			name="Debug",
			menuCaption="&amp;Debug",
			dialog="_gnuc_options_form Run/Debug",
			buildFirst="1",
			captureOutputWith="ProcessBuffer",
			deletable="0",
			saveOption="SaveNone",
			runFromDir="%rw",
		}
		local exec = { cmdLine = "" }
		if cfg.kind == premake.WINDOWEDAPP or cfg.kind == p.CONSOLEAPP then
			exec.cmdLine = 'vsdebugio -prog "%o"'
		end
		m.emit_target(options, exec)
	end

	function m.execute(cfg)
		local options = {
			name="Execute",
			menuCaption="E&amp;xecute",
			dialog="_gnuc_options_form Run/Debug",
			buildFirst="1",
			captureOutputWith="ProcessBuffer",
			deletable="0",
			saveOption="SaveWorkspaceFiles",
			runFromDir="%rw",
		}
		local exec = { cmdLine = "" }
		if cfg.kind == premake.WINDOWEDAPP or cfg.kind == p.CONSOLEAPP then
			exec.cmdLine = '"%o"'
		end
		m.emit_target(options, exec)
	end

	function m.dash(cfg)
		local options = {
			name="dash",
			menuCaption="-",
			deletable="0",
		}
		m.emit_target(options)
	end

	function m.coptions(cfg, toolset, toolinfo)
		local options = {
			showOnMenu="HideIfNoCmdLine",
			deletable="0",
			saveOption="SaveNone",
		}
		local exec = {
			type = "Slick-C",
		}

		if toolinfo.tool == "gcc" then
			options.name="GNU C Options"
			options.menuCaption="GNU C &amp;Options..."
			exec.cmdLine = "gnucoptions"
		elseif toolinfo.tool == "clang" then
			options.name="Clang Options"
			options.menuCaption="Clang &amp;Options..."
			exec.cmdLine = "clangoptions"
		end

		m.emit_target(options, exec)
	end


-- List

	m.elements.list_cpp = function(cfg)
		return {
			m.kind,
		}
	end

	function m.list(cfg)
		local name = "GNUC Options"
		_p(2, '<List Name="%s">', name)

		p.callArray(m.elements.list_cpp, cfg)

		_p(2, '</List>')
	end

	function m.kind(cfg)
		local values = {
			ConsoleApp = "Executable",
			WindowedApp = "Executable",
			SharedLib = "SharedLibrary",
			StaticLib = "StaticLibrary",
--			Makefile = ???,
--			None = ???,
--			Utility = ???,
		}

		if values[cfg.kind] == nil then
			return
		end

		_p(3, '<Item')
		_p(4, 'Name="LinkerOutputType"')
		_p(4, 'Value="%s"/>', values[cfg.kind])
	end


-- Dependencies

	function m.dependencies(cfg)

		local prj = cfg.project
		local dependencies = project.getdependencies(prj)
		if #dependencies > 0 then

			local name = slickedit.cfgname(cfg)
			_p(2, '<Dependencies Name="%s">', name)

			for _, dependency in ipairs(dependencies) do
				_p(3, '<Dependency Project="%s.vpj"/>', dependency.filename) -- TODO: filename should already have extension. no?
			end

			_p(2, '</Dependencies>');
		end

	end


-- PreBuildCommands

	function m.prebuild(cfg)

		if #cfg.prebuildcommands > 0 then

			local stopOnError = "" -- ' StopOnError="1"'
			_p(2, '<PreBuildCommands%s>', stopOnError)

			if cfg.prebuildmessage then
				-- TODO emit an echo statement or something?
			end

			for i, cmd in ipairs(cfg.prebuildcommands) do
				_p(3, '<Exec CmdLine=%s/>', m.quote_string(cmd))
			end

			_p(2, '</PreBuildCommands>')
		end

	end


-- PreBuildCommands

	function m.postbuild(cfg)

		if #cfg.postbuildcommands > 0 then

			local stopOnError = "" -- ' StopOnError="1"'
			_p(2, '<PreBuildCommands%s>', stopOnError)

			if cfg.postbuildmessage then
				-- TODO emit an echo statement or something?
			end

			for i, cmd in ipairs(cfg.postbuildcommands) do
				_p(3, '<Exec CmdLine=%s/>', m.quote_string(cmd))
			end

			_p(2, '</PreBuildCommands>')
		end

	end


-- Libs

	function m.libs(cfg, toolset)

		local links = toolset.getlinks(cfg)

		if #links > 0 then

			local preObjects = "0"
			_p(2, '<Libs PreObjects="%s">', preObjects)

			for _, lib in ipairs(links) do
				_p(3, '<Lib File=%s/>', m.quote_string(lib))
			end

			_p(2, '</Libs>')

		end

	end


-- Inlcude

	function m.includes(cfg)

		if #cfg.includedirs > 0 then

			_p(2, '<Includes>')

			for _, dir in ipairs(cfg.includedirs) do
				dir = project.getrelative(cfg.project, dir)
				_p(3, '<Include Dir=%s/>', m.quote_string(dir))
			end

			_p(2, '</Includes>')
		end

	end


-- Files

	function m.files(prj)
		_p(1, '<Files AutoFolders="DirectoryView">')

		local tr = project.getsourcetree(prj)
		tree.traverse(tr, {
			-- folders are handled at the internal nodes
			onbranchenter = function(node, depth)
--				_p(depth, '<VirtualDirectory Name="%s">', node.name)
			end,
			onbranchexit = function(node, depth)
--				_p(depth, '</VirtualDirectory>')
			end,
			-- source files are handled at the leaves
			onleaf = function(node, depth)
				_p(depth, '<F N="%s"/>', node.relpath)
			end,
		}, false, 1)

		_p(1, '</Files>')
	end


--
-- Project: Generate the SlickEdit project file.
--

	m.elements.config = function(cfg)
		return {
			m.menu,
			m.list,
			m.dependencies,
			m.prebuild,
			m.postbuild,
			m.libs,
			m.includes,
		}
	end

	m.config_elements = {
		"Name",
		"Type",
		"DebugCallbackName",
		"Version",
		"OutputFile",
		"CompilerConfigName",
		"Defines",
	}
	function m.generate(prj)
		p.utf8()

		-- Header
		_p('<!DOCTYPE Project SYSTEM "http://www.slickedit.com/dtd/vse/10.0/vpj.dtd">')

		local version = "10.0"
		local template = "GNU C/C++"
		local workingDirectory = "."
		local buildSystem = "vsbuild"

		_p('<Project')
		_p(1, 'Version="%s"', version)
		_p(1, 'VendorName="SlickEdit"')
		_p(1, 'TemplateName="%s"', template)
		_p(1, 'WorkingDir="%s"', workingDirectory)
		_p(1, 'BuildSystem="%s">', buildSystem)

		-- Configs
		for cfg in project.eachconfig(prj) do

			local tool, toolver = p.config.toolset(cfg)
			tool = tool or "gcc"
			local toolset = premake.tools[tool]
			local toolinfo = { tool=tool, version=toolver }

			local config_attrib = {
				name = slickedit.cfgname(cfg),
				type = "gnuc",
				debugCallbackName = "gdb",
				version = "1",
				outputFile = cfg.buildtarget.relpath,
				compilerConfigName = "Latest Version",
			}

			-- defines and undefines
			if #cfg.defines > 0 or #cfg.undefines > 0 then
				local def, undef
				if #cfg.defines > 0 then
					def = table.implode(cfg.defines, '"/D', '"', ' ')
				end
				if #cfg.undefines > 0 then
					undef = table.implode(cfg.undefines, '"/U', '"', ' ')
				end
				if def and undef then
					config_attrib.defines = def .. " " .. undef
				else
					config_attrib.defines = def or undef
				end
			end

			m.emit_element(1, "Config", config_attrib, m.config_elements)


			p.callArray(m.elements.config, cfg, toolset, toolinfo)

			_p(1, '</Config>')
		end

		-- Files
		m.files(prj)

		-- Macros

		-- these are scripts that can be run when the project becomes active...
--		<Macro>
--			<ExecMacro CmdLine="open commands"/>
--		</Macro>

		_p('</Project>')
	end
