# StarbucksInput.coffee

import {strict as assert} from 'assert'
import {
	undef,
	error,
	isEmpty,
	debug,
	unitTesting,
	} from '@jdeighan/coffee-utils'
import {
	splitLine,
	indentLevel,
	undentedStr,
	indentedStr,
	} from '@jdeighan/coffee-utils/indent'
import {StringInput} from '@jdeighan/string-input'
import {numHereDocs, patch} from '@jdeighan/coffee-utils/heredoc'
import {parsetag} from './parsetag.js'
import {isCommand} from './starbucks_commands.js'

# ---------------------------------------------------------------------------
# Must call AFTER removing indentation

shouldSkip = (line) ->

	return (line == '') || line.match(/^#\s/)

# ---------------------------------------------------------------------------
# - returns one of:
#
#     undef - if comment or empty line
#
#     #define varname some string
#
#     { type: 'cmd',
#       cmd: <cmd>,
#       argstr: <argstr>,    # only if non-empty
#       level: <n>,
#       line: <text>,
#       lineNum: <n>,
#       }
#
#     | plain text
#
#     { type: 'text',
#       text: <text>,
#       level: <n>,
#       line: <text>,
#       lineNum: <n>,
#       }
#
#     a.red href="a URL" a link
#
#     { type: 'tag',
#       tag: <tag>
#       subtype: startup | onmount | ondestroy   # only in 'script'
#              | markdown | sourcecode           # only in 'div'
#       hAttr: { class: 'red', href: 'a URL' }
#       containedText: <text>,   # in non-block tags
#       blockText: <text>        # in block tags
#       level: <n>,
#       line: <text>,
#       lineNum: <n>,
#       }

# --- export, just to allow unit testing

export StarbucksMapper = (line, oInput) ->

	assert oInput instanceof StarbucksInput

	# --- line has indentation stripped off
	[level, line] = splitLine(line)

	if shouldSkip(line)
		return undef     # skip comments and blank lines

	lineNum = oInput.lineNum   # save line number
	lBuffer = oInput.lBuffer   # local reference to buffer

	# --- Don't pull additional lines from the buffer directly
	#     always use oInput.fetch() to maintain correct line numbering

	# --- merge all continuation lines
	while (lBuffer.length > 0) && (indentLevel(lBuffer[0]) >= level+2)
		next = undentedStr(oInput.fetch())
		line += ' ' + next

	# --- handle any HEREDOCs
	#        - cannot be empty
	#        - require 1 level indentation for 1st line

	n = numHereDocs(line)
	if (n > 0)
		lSections = []     # --- will have one subarray for each HEREDOC
		while (n > 0)
			lLines = []
			while (lBuffer.length > 0) && not lBuffer[0].match(/^\s*$/)
				lLines.push oInput.fetch()
			if (lBuffer.length == 0)
				error """
						EOF while processing HEREDOC
						at line #{lineNum}
						n = #{n}
						"""
			if (lBuffer.length > 0)
				oInput.fetch()   # empty line

			lSections.push lLines

			n -= 1
		line = patch(line, lSections)

	if hCmd = isCommand(line)
		{cmd, argstr} = hCmd

		# --- First, handle #include, which isn't really a valid command
		if cmd == 'include'
			fileContents = getFileContents(argstr)
			oInput.unfetch(fileContents)
			return undef

		hToken = {
			type: 'cmd',
			cmd: hCmd.cmd,
			level, line, lineNum,
			}
		if hCmd.argstr
			hToken.argstr = hCmd.argstr
		return hToken

	else if lMatches = line.match(///^
			\|
			\s*
			(.*)
			$///)

		return {
			type: 'text',
			text: lMatches[1],
			level, line, lineNum,
			}

	else
		hToken = parsetag(line)
		hToken.type    = 'tag'
		hToken.level   = level
		hToken.line    = line
		hToken.lineNum = lineNum

		if isBlockTag(hToken)
			blockText = fetchBlock(oInput, level+1, hToken)
			if not isEmpty(blockText)
				if hToken.containedText
					error "<#{tag}> with both contained and block text"
				hToken.blockText = blockText
		return hToken

# ---------------------------------------------------------------------------

export isBlockTag = (hToken) ->

	{tag, subtype} = hToken
	return   (tag=='script') \
			|| (tag=='style') \
			|| (tag == 'pre') \
			|| ((tag=='div') && (subtype=='markdown')) \
			|| ((tag=='div') && (subtype=='sourcecode'))

# ---------------------------------------------------------------------------
#    block will be aligned left, but retaining internal indentation
#    block is not checked for comments, commands, etc.

fetchBlock = (oInput, atLevel, hToken) ->

	blockText = ''
	lBuffer = oInput.lBuffer   # save local reference

	while (lBuffer.length > 0)
		if isEmpty(lBuffer[0])
			oInput.fetch()
			continue
		[level, line] = splitLine(lBuffer[0])
		if level < atLevel
			return blockText

		# --- use fetch() to maintain line numbering
		oInput.fetch()
		if line.match(/^\#\s/)
			continue

		newLevel = level - atLevel    # can't be < 0
		newString = indentedStr(line, newLevel) + '\n'
		debug "IN fetchBlock(): newString = '#{newString}'"
		blockText += newString

	debug "IN fetchBlock() - returning '#{blockText}'"
	return blockText

# ---------------------------------------------------------------------------

export class StarbucksInput extends StringInput

	constructor: (content, hOptions={}) ->

		assert not hOptions.mapper?
		hOptions.mapper = StarbucksMapper
		super content, hOptions

# ---------------------------------------------------------------------------

export getFileContents = (filename) ->

	if unitTesting
		return "Contents of #{filename}"
	else if lMatches = filename.match(///^
			(
				[A-Za-z0-9_\.]+  # base file name (i.e. stub)
				\.
				([a-z]+)         # file extension
				)
			$///)
		[_, filename, ext] = lMatches

		# --- get full path to file
		switch ext
			when 'md'
				fullpath = "#{config.markdownDir}/#{filename}"
			else
				error "#include #{filename} - unsupported file ext"

		return slurp(fullpath)

