# 06callbacks.test.coffee

import {
	say,
	undef,
	pass,
	escapeStr,
	setUnitTesting,
	unitTesting,
	} from '@jdeighan/coffee-utils'
import {parsetag, tag2str, attrStr} from '../src/parsetag.js'
import {StarbucksParser} from '../src/StarbucksParser.js'
import {AvaTester} from '@jdeighan/ava-tester'
import {init} from './test_init.js'

strTrace = ''
hCallbacks = {
	header: (kind, lParms, optionstr) ->

		strTrace += "[0] STARBUCKS #{kind}"
		if lParms? && (lParms.length > 0)
			strTrace += " #{lParms.length} parms"
		if optionstr
			strTrace += " #{optionstr}"
		strTrace += "\n"

	command: (cmd, argstr, level) ->
		strTrace += "[#{level}] CMD ##{cmd} #{argstr}\n"

	start_tag: (tag, hAttr, level) ->
		str = attrStr(hAttr)
		strTrace += "[#{level}] START_TAG <#{tag}#{str}>\n"

	end_tag: (tag, level) ->
		strTrace += "[#{level}] END_TAG </#{tag}>\n"

	startup: (text, level) ->
		strTrace += "[#{level}] STARTUP '#{escapeStr(text)}'\n"

	onmount: (text, level) ->
		strTrace += "[#{level}] ONMOUNT '#{escapeStr(text)}'\n"

	ondestroy: (text, level) ->
		strTrace += "[#{level}] ONDESTROY '#{escapeStr(text)}'\n"

	script: (text, level) ->
		strTrace += "[#{level}] SCRIPT '#{escapeStr(text)}'\n"

	style: (text, level) ->
		strTrace += "[#{level}] STYLE '#{escapeStr(text)}'\n"

	pre: (hToken, level) ->
		text = hToken.blockText
		strTrace += "[#{level}] PRE '#{escapeStr(text)}'\n"

	markdown: (text, level) ->
		strTrace += "[#{level}] MARKDOWN '#{escapeStr(text)}'\n"

	sourcecode: (level) ->
		strTrace += "[#{level}] SOURCECODE\n"

	chars: (text, level) ->
		strTrace += "[#{level}] CHARS '#{escapeStr(text)}'\n"

	linenum: (lineNum) ->
		pass    # don't include this in the trace string
	}

# ---------------------------------------------------------------------------

class CallbacksTester extends AvaTester

	transformValue: (input) ->
		strTrace = ''
		parser = new StarbucksParser(hCallbacks)
		parser.parse(input, "unit test")
		return strTrace

tester = new CallbacksTester()

# ---------------------------------------------------------------------------
# --- Test simple HTML

tester.equal 84, """
		#starbucks component
		nav
		""", """
		[0] STARBUCKS component
		[0] START_TAG <nav>
		[0] END_TAG </nav>
		"""

tester.equal 93, """
		#starbucks component
		nav
		h1
		""", """
		[0] STARBUCKS component
		[0] START_TAG <nav>
		[0] END_TAG </nav>
		[0] START_TAG <h1>
		[0] END_TAG </h1>
		"""

tester.equal 105, """
		#starbucks component
		nav
			h1
		""", """
		[0] STARBUCKS component
		[0] START_TAG <nav>
		[1] START_TAG <h1>
		[1] END_TAG </h1>
		[0] END_TAG </nav>
		"""

tester.equal 117, """
		#starbucks component
		nav
			h1 this is a title
		""", """
		[0] STARBUCKS component
		[0] START_TAG <nav>
		[1] START_TAG <h1>
		[2] CHARS 'this is a title'
		[1] END_TAG </h1>
		[0] END_TAG </nav>
		"""

tester.equal 130, """
		#starbucks component
		#if section == 'main'
			nav
				h1 this is a title
		""", """
		[0] STARBUCKS component
		[0] CMD #if section == 'main'
		[1] START_TAG <nav>
		[2] START_TAG <h1>
		[3] CHARS 'this is a title'
		[2] END_TAG </h1>
		[1] END_TAG </nav>
		"""

# ---------------------------------------------------------------------------
# --- Test script

tester.equal 148, """
		#starbucks component
		h1 title
		script
			x = 23
			parse(this)
		footer the end
		""", """
		[0] STARBUCKS component
		[0] START_TAG <h1>
		[1] CHARS 'title'
		[0] END_TAG </h1>
		[0] SCRIPT 'x = 23\\nparse(this)\\n'
		[0] START_TAG <footer>
		[1] CHARS 'the end'
		[0] END_TAG </footer>
		""", 1

# ---------------------------------------------------------------------------
# --- Test onmount

tester.equal 169, """
		#starbucks webpage
		main
			slot
		script:onmount
			x = 23
		""", """
		[0] STARBUCKS webpage
		[0] START_TAG <main>
		[1] START_TAG <slot>
		[1] END_TAG </slot>
		[0] END_TAG </main>
		[0] ONMOUNT 'x = 23\\n'
		"""

# ---------------------------------------------------------------------------
# --- Test ondestroy

tester.equal 187, """
		#starbucks webpage
		main
			slot
		script:ondestroy
			x = 23
		""", """
		[0] STARBUCKS webpage
		[0] START_TAG <main>
		[1] START_TAG <slot>
		[1] END_TAG </slot>
		[0] END_TAG </main>
		[0] ONDESTROY 'x = 23\\n'
		"""

# ---------------------------------------------------------------------------
# --- Test style

tester.equal 205, """
		#starbucks webpage
		main
			slot
		style
			nav
				overflow: auto

			main
				overflow: auto
		""", """
		[0] STARBUCKS webpage
		[0] START_TAG <main>
		[1] START_TAG <slot>
		[1] END_TAG </slot>
		[0] END_TAG </main>
		[0] STYLE 'nav\\n\\toverflow: auto\\nmain\\n\\toverflow: auto\\n'
		"""

# ---------------------------------------------------------------------------
# --- Test markdown

tester.equal 227, """
		#starbucks webpage
		div:markdown # title
		""", """
		[0] STARBUCKS webpage
		[0] START_TAG <div class="markdown">
		[1] MARKDOWN '# title\\n'
		[0] END_TAG </div>
		"""

# ---------------------------------------------------------------------------
# --- Test markdown

tester.equal 240, """
		#starbucks webpage
		div:markdown
				# title
		""", """
		[0] STARBUCKS webpage
		[0] START_TAG <div class="markdown">
		[1] MARKDOWN '# title\\n'
		[0] END_TAG </div>
		"""

# ---------------------------------------------------------------------------
# --- Test included markdown

tester.equal 254, """
		#starbucks webpage

		div:markdown
			#include webcoding.md
		""", """
		[0] STARBUCKS webpage
		[0] START_TAG <div class="markdown">
		[1] MARKDOWN 'Contents of webcoding.md\\n'
		[0] END_TAG </div>
		"""

# ---------------------------------------------------------------------------
