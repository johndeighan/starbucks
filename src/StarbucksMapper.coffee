# StarbucksMapper.coffee

import {
	undef, assert, croak, isEmpty, nonEmpty, isUniqueList,
	} from '@jdeighan/coffee-utils'
import {debug} from '@jdeighan/coffee-utils/debug'
import {TreeMapper} from '@jdeighan/mapper/tree'
import {parsetag, isBlockTag} from '@jdeighan/mapper/parsetag'
import {SvelteOutput} from '@jdeighan/svelte-output'

import {isCmd, foundCmd, endCmd} from '@jdeighan/starbucks/commands'

# ---------------------------------------------------------------------------

export class StarbucksMapper extends TreeMapper

	constructor: (content, source) ->

		super content, source
		@rootDir = @hSourceInfo.dir   # used for file searches
		@kind = undef                 # if set, we've seen the header line

	# ..........................................................

	mapNode: (line, level) ->

		# --- Commands don't come here - they go to handleCommand()
		#     Comments don't come here - they go to handleComment()
		#     Empty lines don't come here - they go to handleEmptyLine()

		debug "enter mapNode(level=#{level})", line

		# --- treat as an element
		hToken = parsetag(line)

		# --- if one of:
		#        script,
		#        style,
		#        pre,
		#        div:markdown,
		#        div:sourcecode
		if isBlockTag(hToken)
			hToken.blockText = @fetchBlock(level+1)

		debug 'return from mapNode()', hToken
		return hToken

	# ..........................................................
	# --- This only creates a node in the tree
	#     The command is actually handled when the tree is walked

	handleCommand: (cmd, argstr, level) ->

		debug "enter StarbucksMapper.handleCommand('#{cmd}', '#{argstr}')"

		# --- CieloMapper.handleCommand must be given a chance
		#     to handle #define commands since lines automatically
		#     have variables substituted

		lResult = super(cmd, argstr, level)
		[handled, result] = lResult
		if handled
			return lResult

		if (cmd == 'starbucks')
			assert (@kind == undef), "multiple #starbucks headers"
			assert level==0, "#starbucks - level is #{level}, not 0"
			hToken = @parseHeaderLine(argstr)
			assert (@kind != undef), "header failed to set kind"
		else
			assert (@kind != undef), "missing #starbucks header"
			assert isCmd(cmd), "Unknown command: '#{cmd} #{argstr}'"
			hToken = {
				type: 'command'
				cmd
				argstr
				}

		debug "return from StarbucksMapper.handleCommand()", hToken
		return [true, hToken]

	# ..........................................................

	parseHeaderLine: (argstr) ->

		lMatches = argstr.match(///^
				( webpage | component )
				\s*
				(?:   # parameters
					\(         # open paren
					([^\)]*)   # anything except ) - parameters to component
					\)         # close paren
					\s*
					)?
				(.*)       # options
				$///)

		assert lMatches, "Invalid #starbucks header line: '#starbucks #{argstr}'"
		[_, kind, parms, optionstr] = lMatches
		@kind = kind

		if nonEmpty(parms)
			lParms = parms.trim().split(/\s*,\s*/)
			assert isUniqueList(lParms), "parameters not unique"
		else
			lParms = undef

		# --- if debugging, turn it on before calling debug()
		if optionstr && optionstr.match(/// [^\s] debug [\s$] ///)
			setDebugging true
		debug "Parsing #starbucks header line"

		if nonEmpty(optionstr)
			for opt in optionstr.trim().split(/\s+/)
				[name, value] = opt.split(/=/, 2)
				debug "HOOK header: OPTION #{name} = '#{value}'"
				switch name
					when 'debug'
						setDebugging true
					when 'store', 'stores'
						hStores = {}
						for name in value.split(/\,/)
							filename = mkpath(name, '.store')
							fullpath = pathTo(filename, @rootDir)
							assert fullpath?, "No such store: #{filename}"
							hStores[name] = fullpath
					when 'keyhandler'
						# @oOutput.putLine "<svelte:window on:keydown={#{value}}/>"
						keyhandler = value
					else
						error "Unknown option: #{name}"
		return {
			type: 'header'
			kind
			lParms
			hStores
			keyhandler
			}

	# ..........................................................

	visit: (node, hInfo, level) ->

		return

	# ..........................................................

	endVisit: (node, hInfo, level) ->

		return

	# ..........................................................

	getResult: () ->

		return undef

# ---------------------------------------------------------------------------
