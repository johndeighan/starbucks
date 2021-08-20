# CallbackHooks.coffee

import {escapeStr, oneline} from '@jdeighan/coffee-utils'
import {parsetag, attrStr} from '@jdeighan/starbucks/parser'

strTrace = ''

# ---------------------------------------------------------------------------

export clearTrace = () ->

	strTrace = ''
	return

# ---------------------------------------------------------------------------

export getTrace = () ->

	return strTrace

# ---------------------------------------------------------------------------

export getHooks = () =>

	return {
		header: (kind, lParms, optionstr) ->

			strTrace += "[0] STARBUCKS #{kind}"
			if lParms? && (lParms.length > 0)
				strTrace += " #{lParms.length} parms"
			if optionstr
				strTrace += " #{optionstr}"
			strTrace += "\n"
			return

		start_cmd: (cmd, argstr, level) ->
			if argstr
				strTrace += "[#{level}] CMD #{cmd} #{argstr}\n"
			else
				strTrace += "[#{level}] CMD #{cmd}\n"
			return

		end_cmd: (cmd, level) ->
			strTrace += "[#{level}] END_CMD #{cmd}\n"
			return

		start_tag: (tag, hAttr, level) ->
			str = attrStr(hAttr)
			strTrace += "[#{level}] TAG <#{tag}#{str}>\n"
			return

		end_tag: (tag, level) ->
			strTrace += "[#{level}] END_TAG </#{tag}>\n"
			return

		startup: (text, level) ->
			strTrace += "[#{level}] STARTUP '#{escapeStr(text)}'\n"
			return

		onmount: (text, level) ->
			strTrace += "[#{level}] ONMOUNT '#{escapeStr(text)}'\n"
			return

		ondestroy: (text, level) ->
			strTrace += "[#{level}] ONDESTROY '#{escapeStr(text)}'\n"
			return

		script: (text, level) ->
			strTrace += "[#{level}] SCRIPT '#{escapeStr(text)}'\n"
			return

		style: (text, level) ->
			strTrace += "[#{level}] STYLE '#{escapeStr(text)}'\n"
			return

		pre: (hTag, level) ->
			text = hTag.blockText
			strTrace += "[#{level}] PRE '#{escapeStr(text)}'\n"
			return

		markdown: (hTag, level) ->
			text = hTag.blockText
			strTrace += "[#{level}] MARKDOWN '#{escapeStr(text)}'\n"
			return

		sourcecode: (level) ->
			strTrace += "[#{level}] SOURCECODE\n"
			return

		chars: (text, level) ->
			strTrace += "[#{level}] CHARS '#{escapeStr(text)}'\n"
			return

		linenum: (lineNum) ->
			pass    # don't include this in the trace string
			return

		}
