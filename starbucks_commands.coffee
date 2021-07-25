# starbucks_commands.coffee

import {strict as assert} from 'assert'
import {config} from './starbucks.config.js'
import {
	error,
	undef,
	say,
	pass,
	stringToArray,
	truncateBlock,
	unitTesting,
	debug,
	debugging,
	} from '@jdeighan/coffee-utils'
import {indentedBlock, indentedStr} from '@jdeighan/coffee-utils/indent'
import {StarbucksOutput, Output} from './Output.js'
import {markdownify, markdownifyFile} from './markdownify.js'
import {svelteEsc} from './svelte_utils.js'

# ---------------------------------------------------------------------------
# Entries on the command stack have:
#       {
#          cmd:   <cmdName>,
#          state: <cmdState>,
#          level: <level>,
#          }
#    where <cmdState> is an integer

# --- Export, to allow unit testing

export lCmdStack = []

# --- utility methods
lCmdStack.empty = () ->
	return this.length == 0
lCmdStack.nonempty = () ->
	return this.length > 0
lCmdStack.TOS = () ->
	if this.nonempty()
		return this[this.length - 1];
	else
		return undef
lCmdStack.dump = () ->
	if lCmdStack.nonempty()
		say "   STACK:"
		pos = lCmdStack.length
		while (pos > 0)
			pos -= 1
			h = lCmdStack[pos]
			say "      cmd=#{h.cmd} state=#{h.state} level=#{h.level}"
	else
		say "   STACK: empty"
	return

# ---------------------------------------------------------------------------
# 1. Ends all commands at a higher level than 'level'
# 2. Throws an error if this command isn't allowed here
# 3. May return text to be inserted

export foundCmd = (cmd, argstr, level, oOut) ->

	if oOut not instanceof Output
		error "foundCmd(): oOut not instance of Output"

	debug "DEBUG: foundCmd('#{cmd}','#{argstr}',#{level}"

	# --- This ends all commands at level higher than 'level'
	atLevel(level, oOut)

	cur = lCmdStack.TOS()

	if cur && isTrueCmd(cmd) && (cur.level == level)
		# --- end the current command, exec new command
		endCmd cur, oOut
		execCmd cmd, argstr, level, oOut

		# --- simply replace current TOS with this command
		lCmdStack[lCmdStack.length - 1] = {cmd, state:1, level}

	else if lCmdStack.empty() || (level > cur.level)
		# --- lower level, start a new command
		execCmd cmd, argstr, level, oOut
		lCmdStack.push { cmd, state: 1, level}
	else
		execCmd cmd, argstr, level, oOut

		# --- check if this command is allowed here
		#     throws error if invalid transition

		next = nextState(cur.cmd, cur.state, cmd)

		debug "   NEXT STATE: #{next}"
		if not next?
			error "Bad command ##{cmd} - "
		lCmdStack.TOS().state = next

	if debugging
		lCmdStack.dump()

	return

# ---------------------------------------------------------------------------

export finished = (oOut) ->

	atLevel -1, oOut
	return

# ---------------------------------------------------------------------------
#       Utility functions
# ---------------------------------------------------------------------------
#    End all commands at higher level

atLevel = (level, oOut) ->

	if oOut not instanceof Output
		error "atLevel(): oOut not instance of Output"

	# --- End all commands at higher level

	while lCmdStack.nonempty() && (lCmdStack.TOS().level > level)
		hCmd = lCmdStack.pop()
		endCmd(hCmd, oOut)
	return

# ---------------------------------------------------------------------------

isTrueCmd = (cmd) ->

	return (['if','for','await','const','log'].indexOf(cmd) >= 0)

# ---------------------------------------------------------------------------
# Should throw error if the command can't end in its current state

endCmd = (hCmd, oOut) ->

	if not hCmd
		error "endCmd(): empty command rec"

	{cmd, state, level} = hCmd
	debug "DEBUG: endCmd #{cmd}"

	switch cmd
		when 'if'
			oOut.put "\{\/if\}", level
		when 'for'
			oOut.put "\{\/each\}", level
		when 'await'
			if (state == 1)
				error "endCmd('#await'): #then section expected"
			oOut.put "\{\/await\}", level
		when 'const', 'log'
			pass
		else
			error "endCmd('##{cmd}'): Not a true command"
	return

# ---------------------------------------------------------------------------

nextState = (cmd, state, newCmd) ->

	if not hTransitions[cmd]?
		return undef
	hStates = hTransitions[cmd]
	if not hStates[state]?
		return undef
	hCmds = hStates[state]
	if not hCmds[newCmd]
		return undef
	return hCmds[newCmd]

# ---------------------------------------------------------------------------

hTransitions = {}

# ---------------------------------------------------------------------------

allow = (cmd, state, nextCmd, nextState) ->

	if not hTransitions[cmd]
		hTransitions[cmd] = {}
	if not hTransitions[cmd][state]
		hTransitions[cmd][state] = {}
	if not hTransitions[cmd][state][nextCmd]
		hTransitions[cmd][state][nextCmd] = nextState
	return

# ---------------------------------------------------------------------------

allow 'if',    1, 'elsif', 1
allow 'if',    1, 'else',  2

allow 'await', 1, 'then',  2
allow 'await', 2, 'catch', 3

# ---------------------------------------------------------------------------
# export because this is called directly in blocks, e.g.
#           div:markdown
#           script
#           style

export execCmd = (cmd, argstr, level, oOut) ->

	assert oOut instanceof StarbucksOutput
	switch cmd
		when 'const'
			lMatches = argstr.match(///^
					([A-Za-z_][A-Za-z0-9_]*)  # const name
					\s*
					=
					(.*)                      # expression
					$///)
			if lMatches?
				[_, name, value] = lMatches
				oOut.setConst name, value.trim()
			else
				error "Invalid #const command"
			return

		when 'if'
			oOut.put "\{\#if #{argstr}\}", level
			return

		when 'elsif'
			oOut.put "\{\:else if #{argstr}\}", level
			return

		when 'else'
			if argstr
				error "#else cannot have arguments"
			oOut.put "\{\:else\}", level
			return

		when 'for'
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
			oOut.put "\{#{eachstr}\}", level
			return

		when 'await'
			oOut.put "\{\#await #{argstr}\}", level
			return

		when 'then'
			oOut.put "\{\:then #{argstr}\}", level
			return

		when 'catch'
			oOut.put "\{\:catch #{argstr}\}", level
			return

		when 'log'
			if argstr == "on" or argstr == ""
				oOut.doLog(true)
			else if argstr == "off"
				oOut.doLog(false)
			else
				throw "Invalid #log command"
			return

		else
			error "execCmd(): Unknown command: '#{cmd}'"
	return

# ---------------------------------------------------------------------------
# if true, returns { cmd, argstr }

export isCommand = (line, wantCmd=undef) ->

	assert not line.match(/^\s/)

	lMatches = line.match(///^
			\# (\S+)
			\s*                # skip whitespace following command
			(.*)               # command arguments
			$///)

	if not lMatches
		return undef

	[_, cmd, argstr] = lMatches
	if wantCmd && (cmd != wantCmd)
		return undef

	hToken = { cmd }
	if argstr
		hToken.argstr = argstr
	return hToken
