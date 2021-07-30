# 06tokens.test.coffee

import {say, normalize, debug, setDebugging} from '@jdeighan/coffee-utils'
import {stdImportStr} from '../src/Output.js'
import {StarbucksInput} from '../src/StarbucksInput.js'
import {AvaTester} from '@jdeighan/ava-tester'
import {init} from './test_init.js'

# ---------------------------------------------------------------------------

class TokenTester extends AvaTester

	transformValue: (content) ->

		debug "CALL transformValue()"
		oInput = new StarbucksInput(content)
		lTokens = []
		while hToken = oInput.get()
			debug hToken, "hToken:"
			if hToken.containedText?
				hToken.containedText = normalize(hToken.containedText)
			lTokens.push(hToken)
		return lTokens

tester = new TokenTester()

# ---------------------------------------------------------------------------

tester.equal -26, """
		div
		""", [{
			type: 'tag'
			tag: 'div'
			line: 'div'
			level: 0
			lineNum: 1
			}]

# ---------------------------------------------------------------------------

tester.equal 38, """
		div:markdown
		""", [{
			type: 'tag'
			tag: 'div'
			subtype: 'markdown'
			hAttr: {
				class: {
					value: 'markdown',
					quote: '"',
					},
				},
			line: 'div:markdown'
			level: 0
			lineNum: 1
			}]

# ---------------------------------------------------------------------------

tester.equal 57, """
		div:markdown **bold**
		""", [{
			type: 'tag'
			tag: 'div'
			subtype: 'markdown'
			hAttr: {
				class: {
					value: 'markdown',
					quote: '"',
					},
				},
			containedText: '**bold**'
			line: 'div:markdown **bold**'
			level: 0
			lineNum: 1
			}]

# ---------------------------------------------------------------------------

tester.equal 77, """
		div:markdown
				**bold**
		""", [{
			type: 'tag'
			tag: 'div'
			subtype: 'markdown'
			hAttr: {
				class: {
					value: 'markdown',
					quote: '"',
					},
				},
			containedText: '**bold**'
			line: 'div:markdown **bold**'
			level: 0
			lineNum: 1
			}]

# ---------------------------------------------------------------------------

tester.equal 98, """
		div:markdown
			#include sample.md
		""", [{
			type: 'tag'
			tag: 'div'
			subtype: 'markdown'
			hAttr: {
				class: {
					value: 'markdown',
					quote: '"',
					},
				},
			line: 'div:markdown'
			level: 0
			lineNum: 1,
			blockText: "#include sample.md\n"
			}]

# ---------------------------------------------------------------------------

tester.equal 119, """
		#if x==3
		#elsif x==4
		#else
		""", [
			{
				type: 'cmd'
				cmd: 'if'
				argstr: 'x==3'
				line: '#if x==3'
				level: 0
				lineNum: 1
				},
			{
				type: 'cmd'
				cmd: 'elsif'
				argstr: 'x==4'
				line: '#elsif x==4'
				level: 0
				lineNum: 2
				},
			{
				type: 'cmd'
				cmd: 'else'
				line: '#else'
				level: 0
				lineNum: 3
				},
			]
