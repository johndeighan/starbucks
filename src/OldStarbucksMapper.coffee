# StarbucksMapper.coffee

import {
	assert, pass, undef, error, warn, isEmpty, nonEmpty, isString, CWS,
	sep_dash, sep_eq,
	} from '@jdeighan/coffee-utils'
import {arrayToBlock, firstLine} from '@jdeighan/coffee-utils/block'
import {debug, setDebugging} from '@jdeighan/coffee-utils/debug'
import {log, LOG, stringify} from '@jdeighan/coffee-utils/log'
import {untabify} from '@jdeighan/coffee-utils/indent'
import {TreeMapper} from '@jdeighan/mapper/tree'
import {isTAML, taml} from '@jdeighan/mapper/taml'
import {SvelteOutput} from '@jdeighan/svelte-output'
import {mapHereDoc, isFunctionHeader} from '@jdeighan/mapper/heredoc'
import {parsetag, isBlockTag, tag2str} from '@jdeighan/mapper/parsetag'

###

TreeMapper already handles:
	- #include
	- continuation lines
	- HEREDOCs

However, it's handling of HEREDOCs does not evaluate the HEREDOC sections,
so we override patchLine() to call patch() with evaluate = true

We leave handleEmptyLine() alone, so empty lines will be skipped

Furthermore TreeMapper treats all lines as simply strings. We need to
generate objects with key 'type' so we override mapString() to
generate objects

###

# ---------------------------------------------------------------------------
# export to allow unit testing

export splitHeredocHeader = (line) ->

	lParts = line.trim().split(/\s+/)
	if (lParts.length == 1)
		return [lParts[0], undef]
	else if (lParts.length == 2)
		return lParts
	else
		return undef

# ---------------------------------------------------------------------------
#   class StarbucksMapper

export class StarbucksMapper extends TreeMapper

	constructor: (content, source, @oOutput) ->

		super content, source
		assert @oOutput, "StarbucksMapper: oOutput is undef"
		assert @oOutput instanceof SvelteOutput,
				"StarbucksMapper: oOutput not a SvelteOutput"

	# ..........................................................

	mapHereDoc: (block) ->
		# --- override to create anonymous variable
		#     Distinct from the mapHereDoc() function found in /heredoc

		hResult = mapHereDoc(block)
		assert isHash(hResult), "mapHereDoc(): hResult not a hash"
		varname = @oOutput.addVar(hResult.str)
		return hResult

	# ..........................................................

	mapNode: (line, level) ->
		LOG line, 'line', '+'
		# --- empty lines and comments have been handled
		#     line has been split into (level, str)
		#     continuation lines have been merged
		#     HEREDOC sections have been patched
		#     if undef is returned, the line is ignored

		assert isString(line), "StarbucksMapper.mapNode(): not a string"
		if lMatches = line.match(///^
				\#
				([a-z]*)   # command (or empty for comment)
				\s*        # skip whitespace
				(.*)       # the rest of the line
				$///)
			[_, cmd, rest] = lMatches
			if (cmd.length == 0)
				return undef
			if (cmd == 'starbucks')
				hToken = @parseHeaderLine(rest)
			else
				hToken = @parseCommand(cmd, rest)
		else
			# --- treat as an element
			hToken = parsetag(line)
			LOG hToken, 'hToken'

			# --- if one of:
			#        script,
			#        style,
			#        pre,
			#        div:markdown,
			#        div:sourcecode
			if isBlockTag(hToken)
				hToken.blockText = @fetchBlock(level+1)

		debug 'hToken', hToken
		return hToken

	# ..........................................................

	parseHeaderLine: (rest) ->

		lMatches = rest.match(///^
				( webpage | component )
				\s*
				(?:   # parameters
					\(         # open paren
					([^\)]*)   # anything except ) - parameters to component
					\)         # close paren
					\s*
					)?
				(.*)       # options
				\s*        # allow trailing whitespace
				$///)

		assert lMatches, "Invalid #starbucks header"
		[_, kind, parms, optionstr] = lMatches
		if parms?
			parms = parms.trim()

		# --- if debugging, turn it on before calling debug()
		if optionstr && optionstr.match(/\bdebug\b/)
			setDebugging true

		debug "Parsing #starbucks header line"

		hToken = {
			type: "#starbucks"
			kind: kind
			}
		if optionstr
			hToken.optionstr = optionstr
		if parms
			hToken.lParms = parms.split(/\s*,\s*/)

		debug 'GOT TOKEN', hToken
		return hToken

	# ..........................................................

	parseCommand: (cmd, rest) ->

		hToken = {type: "##{cmd}"}
		if rest
			hToken.argstr = rest
		return hToken

# ---------------------------------------------------------------------------
