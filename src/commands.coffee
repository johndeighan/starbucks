# commands.coffee

import {
	assert, error, undef, pass, words,
	} from '@jdeighan/coffee-utils'
import {log} from '@jdeighan/coffee-utils/log'
import {debug} from '@jdeighan/coffee-utils/debug'
import {SvelteOutput} from '@jdeighan/svelte-output'

lCommands = words('if elsif else for await then catch log error')

# ---------------------------------------------------------------------------

export isCmd = (cmd) ->

	return cmd in lCommands

# ---------------------------------------------------------------------------

export foundCmd = (cmd, argstr, level, oOutput) ->

	assert oOutput instanceof SvelteOutput,\
			"foundCmd(): oOutput not instance of SvelteOutput"
	switch cmd
		when '#if'
			oOutput.putCmdWithExpr '{#if ', argstr, '}', level
			return

		when '#elsif'
			oOutput.putCmdWithExpr '{:else if ', argstr, '}', level
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
				error "Invalid #for command"
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

		when '#log'
			log argstr
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
