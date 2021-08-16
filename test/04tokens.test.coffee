# 04tokens.test.coffee

import {loadEnvFrom} from '@jdeighan/env'
import {AvaTester} from '@jdeighan/ava-tester'
import {say, normalize, setUnitTesting} from '@jdeighan/coffee-utils'
import {mydir} from '@jdeighan/coffee-utils/fs'
import {debug, setDebugging} from '@jdeighan/coffee-utils/debug'
import {stdImportStr} from '@jdeighan/svelte-output'
import {StarbucksInput} from '../src/StarbucksInput.js'

dir = mydir(`import.meta.url`)
loadEnvFrom(dir)

setUnitTesting(true)

# ---------------------------------------------------------------------------

class TokenTester extends AvaTester

	transformValue: (content) ->

		oInput = new StarbucksInput(content)
		lTokens = []
		while hToken = oInput.get()
			if hToken.containedText?
				hToken.containedText = normalize(hToken.containedText)
			lTokens.push(hToken)
		return lTokens

tester = new TokenTester()

# ---------------------------------------------------------------------------

tester.equal 29, """
		div
		""", [{
			type: 'tag'
			tag: 'div'
			line: 'div'
			level: 0
			lineNum: 1
			}]

# ---------------------------------------------------------------------------

tester.equal 41, """
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

tester.equal 60, """
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

tester.equal 80, """
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

tester.equal 101, """
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

tester.equal 122, """
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
