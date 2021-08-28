# starbucks_commands.coffee

import {strict as assert} from 'assert'
import {
	error, undef, say, pass,
	stringToArray, truncateBlock, unitTesting,
	} from '@jdeighan/coffee-utils'
import {debug, debugging, setDebugging} from '@jdeighan/coffee-utils/debug'
import {indentedBlock, indentedStr} from '@jdeighan/coffee-utils/indent'
import {SvelteOutput} from '@jdeighan/svelte-output'

# ---------------------------------------------------------------------------

export foundCmd = (cmd, argstr, level, oOutput) ->

	assert oOutput instanceof SvelteOutput,\
			"foundCmd(): oOutput not instance of SvelteOutput"
	switch cmd
		when '#envvar'
			lMatches = argstr.match(///^
					([A-Za-z_][A-Za-z0-9_]*)  # env var name
					\s*
					=
					(.*)                      # expression
					$///)
			if lMatches?
				[_, name, value] = lMatches
				process.env[name] = value.trim()
			else
				error "Invalid #envvar command"
			return

		when '#if'
			oOutput.putStr('{#if')
			oOutput.putExpr(argstr)  # convert to CoffeeScript
			oOutput.putStr('}')
			oOutput.endStr(level)
			return

		when '#elsif'
			oOutput.putStr('{:else if')
			oOutput.putExpr(argstr)  # convert to CoffeeScript
			oOutput.putStr('}')
			oOutput.endStr(level)
			return

		when '#else'
			if argstr
				error "#else cannot have arguments"
			oOutput.putLine "\{\:else\}", level
			return

		when '#for'
			lMatches = argstr.match(///^
					([A-Za-z_][A-Za-z0-9_]*)     # variable name
					(?:
						,
						([A-Za-z_][A-Za-z0-9_]*)  # index variable name
						)?
					\s+
					in
					\s+
					(.*?)
					(?:
						\s* \( \s* key \s* = \s*  # '(key = '
						(.*)                      # the key
						\s* \)                    # ')'
						)?                        # key is optional
					$///)
			if lMatches?
				[_, varname, index, expr, key] = lMatches
				if index
					eachstr = "\#each #{expr} as #{varname},#{index}"
				else
					eachstr = "\#each #{expr} as #{varname}"
				if key
					eachstr += " (#{key})"
			else
				throw "Invalid #for command"
			oOutput.putLine "\{#{eachstr}\}", level
			return

		when '#await'
			oOutput.putLine "\{\#await #{argstr}\}", level
			return

		when '#then'
			oOutput.putLine "\{\:then #{argstr}\}", level
			return

		when '#catch'
			oOutput.putLine "\{\:catch #{argstr}\}", level
			return

		when '#dolog'
			oOutput.doLog true
			return

		when '#dontlog'
			oOutput.doLog false
			return

		when '#log'
			oOutput.log argstr
			return

		when '#error'
			oOutput.putLine "<div class=\"error\">#{argstr}</div>"
			return

		else
			error "foundCmd(): Unknown command: '#{cmd}'"
	return

# ---------------------------------------------------------------------------

export endCmd = (cmd, level, oOutput) ->

	assert cmd?, "endCmd(): empty cmd"
	switch cmd
		when '#if'
			oOutput.putLine "\{\/if\}", level
		when '#for'
			oOutput.putLine "\{\/each\}", level
		when '#await'
			oOutput.putLine "\{\/await\}", level
	return
