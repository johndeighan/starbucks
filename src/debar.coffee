# debar.coffee

import {assert} from '@jdeighan/unit-tester/utils'
import {
	undef, pass, OL, isEmpty, nonEmpty, replaceVars,
	} from '@jdeighan/coffee-utils'
import {indented, indentation} from '@jdeighan/coffee-utils/indent'
import {toArray, toBlock} from '@jdeighan/coffee-utils/block'
import {debug} from '@jdeighan/coffee-utils/debug'
import {Mapper, map} from '@jdeighan/mapper'
import {TreeWalker} from '@jdeighan/mapper/tree'

export sep = '='

# ---------------------------------------------------------------------------

export debarStr = (str, level=0) ->

	assert (str != sep), "cannot use with #{OL(sep)}"
	return "#{indentation(level)}\# |||| #{str}"

# ---------------------------------------------------------------------------

export debarSep = () ->

	return "\# |||| #{sep}"

# ---------------------------------------------------------------------------
# Retains comments like:
#    # |||| <anything>
# Removes all other comments
# ---------------------------------------------------------------------------

export class DebarPreMapper extends TreeWalker

	mapComment: (hNode) ->

		{str, uobj, level} = hNode
		{comment} = uobj
		if (comment.indexOf('||||') == 0)
			return str
		else
			return undef

# ---------------------------------------------------------------------------
# Converts:
#    # |||| <anything>
# To:
#    <anything>
# NOTE:
#    maintains indentation
#    allows // in place of #
#
# ---------------------------------------------------------------------------

export class DebarPostMapper extends Mapper

	isComment: (hNode) ->
		# --- Handle both CoffeeScript and JavaScript comments

		if (hNode.str.indexOf('# ') == 0)
			hNode.uobj = {
				comment: hNode.str.substring(2).trim()
				}
			return true
		else if (hNode.str.indexOf('// ') == 0)
			hNode.uobj = {
				comment: hNode.str.substring(3).trim()
				}
			return true
		else
			return false

	# ..........................................................

	mapComment: (hLine) ->

		debug "enter DebarPostMapper.mapComment()", hLine
		{str, uobj, level} = hLine
		{comment} = uobj
		if lMatches = comment.match(///^
				\| \| \| \|       # 4 vertical bars
				\s*
				(.*)
				$///)
			[_, tail] = lMatches
			result = indented(tail, level, @oneIndent)
			debug "return from DebarPostMapper.mapComment()", result
			return result

		debug "return undef from DebarPostMapper.mapComment()"
		return undef

# ---------------------------------------------------------------------------

export debar = (block, source=undef) ->
	# --- Returns an array of blocks

	debug "enter debar()", block
	block = map(source, block, [DebarPreMapper, DebarPostMapper])
	debug "map to", block
	if isEmpty(block)
		debug "return undef from debar() - empty result"
		return ''

	# --- separate into blocks on debarSep()
	lCurBlock = []
	lBlocks = [lCurBlock]    # array of arrays

	for str in toArray(block)
		if (str == sep)
			lCurBlock = []
			lBlocks.push lCurBlock
		else
			lCurBlock.push str

	# --- convert items (which are arrays) to blocks
	lRetVal = []
	for lItems in lBlocks
		lRetVal.push toBlock(lItems)

	debug "return from debar()", lRetVal
	return lRetVal
