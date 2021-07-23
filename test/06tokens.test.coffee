# tokens.test.coffee

import {test_token, show_only} from './test_utils.js'
import {stdImportStr} from '../Output.js'

# ---------------------------------------------------------------------------

test_token 8, """
		div
		""", {
			type: 'tag'
			tag: 'div'
			line: 'div'
			level: 0
			lineNum: 1
			}

# ---------------------------------------------------------------------------

test_token 20, """
		div:markdown
		""", {
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
			}

# ---------------------------------------------------------------------------

test_token 39, """
		div:markdown **bold**
		""", {
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
			}

# ---------------------------------------------------------------------------

test_token 59, """
		div:markdown
				**bold**
		""", {
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
			}

# ---------------------------------------------------------------------------

test_token 80, """
		div:markdown
			#include sample.md
		""", {
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
			}

# ---------------------------------------------------------------------------

test_token 114, """
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

