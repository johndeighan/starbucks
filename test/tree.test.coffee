# tree.test.coffee

import {AvaTester} from '@jdeighan/ava-tester'
import {say, normalize, setUnitTesting, taml} from '@jdeighan/coffee-utils'
import {debug, setDebugging} from '@jdeighan/coffee-utils/debug'
import {StarbucksParser} from '@jdeighan/starbucks/parser'
import {SvelteOutput} from '@jdeighan/svelte-output'

setUnitTesting(true)
simple = new AvaTester()

# ---------------------------------------------------------------------------

class TreeTester extends AvaTester

	transformValue: (text) ->

		parser = new StarbucksParser(text, new SvelteOutput())
		return parser.getTree()

tester = new TreeTester()

# ---------------------------------------------------------------------------
# NOTE: At this point, we don't care if commands are valid commands,
#       nor whether they appear in the correct order (e.g. if there's
#       an #else or #elsif without being introduced by #if)
# ---------------------------------------------------------------------------

tester.equal 24, """
		h1 a title
		""", taml("""
		---
		-
			lineNum: 1
			node:
				type: tag
				tag: h1
				containedText: a title
		""")

# ---------------------------------------------------------------------------

tester.equal 38, """
		div
		h1 a title
		""", taml("""
		---
		-
			lineNum: 1
			node:
				type: tag
				tag: div
		-
			lineNum: 2
			node:
				type: tag
				tag: h1
				containedText: a title
		""")

# ---------------------------------------------------------------------------

tester.equal 58, """
		div
			h1 a title
		""", taml("""
		---
		-
			lineNum: 1
			node:
				type: tag
				tag: div
			body:
				-
					lineNum: 2
					node:
						type: tag
						tag: h1
						containedText: a title
		""", true)

# ---------------------------------------------------------------------------

tester.equal 79, """
		#starbucks component
		div
			h1 a title
		""", taml("""
		---
		-
			lineNum: 1
			node:
				type: '#starbucks'
				kind: component
		-
			lineNum: 2
			node:
				type: tag
				tag: div
			body:
				-
					lineNum: 3
					node:
						type: tag
						tag: h1
						containedText: a title
		""", true)

# ---------------------------------------------------------------------------

tester.equal 105, """
		#if x==0
			p no content
		#elsif x==1
			p one thing
		#else
			h2 many items
		h3 the end
		""", taml("""
		---
		-
			node:
				type: '#if'
				argstr: x==0
			lineNum: 1
			body:
				-
					node:
						type: tag
						tag: p
						containedText: no content
					lineNum: 2
		-
			node:
				type: '#elsif'
				argstr: x==1
			lineNum: 3
			body:
				-
					node:
						type: tag
						tag: p
						containedText: one thing
					lineNum: 4
		-
			node:
				type: '#else'
			lineNum: 5
			body:
				-
					node:
						type: tag
						tag: h2
						containedText: many items
					lineNum: 6
		-
			node:
				type: tag
				tag: h3
				containedText: the end
			lineNum: 7
		""", true)