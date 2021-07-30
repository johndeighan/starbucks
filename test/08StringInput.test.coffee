# 08StringInput.test.coffee

import {strict as assert} from 'assert'
import fs from 'fs'

import {say, undef} from '@jdeighan/coffee-utils'
import {indentLevel, undentedStr} from '@jdeighan/coffee-utils/indent'
import {numHereDocs, patch} from '../src/heredoc_utils.js'
import {StringInput} from '@jdeighan/string-input'
import {AvaTester} from '@jdeighan/ava-tester'
import {config} from '../starbucks.config.js'
import {init} from './test_init.js'

markdownDir = config.markdownDir
assert fs.existsSync(markdownDir), "dir #{markdownDir} doesn't exist"

# ---------------------------------------------------------------------------

class GatherTester extends AvaTester

	transformValue: (input) ->
		if input not instanceof StringInput
			throw new Error("input should be a StringInput object")
		lLines = []
		line = input.get()
		while line?
			lLines.push(line)
			line = input.get()
		return lLines

tester = new GatherTester()

# ---------------------------------------------------------------------------
# --- Test basic reading till EOF

tester.equal 36, new StringInput("""
		abc
		def
		"""), [
		'abc',
		'def',
		]

tester.equal 44, new StringInput("""
		abc

		def
		"""), [
		'abc',
		'',
		'def',
		]

tester.equal 54, new StringInput("""
		abc

		def
		""", {
			mapper: (line) ->
				if line == ''
					return undef
				else
					return line
			}), [
		'abc',
		'def',
		]

# ---------------------------------------------------------------------------
# --- Test basic use of mapping function

(()->
	mapper = (line) ->
		if line == ''
			return undef
		else
			return 'x'

	tester.equal -79, new StringInput("""
			abc

			def
			""", {mapper}), [
			'x',
			'x',
			]
	)()

# ---------------------------------------------------------------------------
# --- Test ability to access 'this' object from a mapper
#     Goal: remove not only blank lines, but also the line following

(()->

	mapper = (line, oInput) ->
		if line == ''
			oInput.get()
			return undef
		else
			return line

	tester.equal 102, new StringInput("""
			abc

			def
			ghi
			""", {mapper}), [
			'abc',
			'ghi',
			]
	)()

# ---------------------------------------------------------------------------
# --- Test handling HEREDOC

(()->

	mapper = (line, oInput) ->
		if line == '' || line.match(/^\s*#\s/)
			return undef     # skip comments and blank lines
		n = numHereDocs(line)
		if (n == 0)
			return line
		lSections = []     # --- will have one subarray for each HEREDOC
		while (n > 0)
			lLines = []
			while (oInput.lBuffer.length > 0) && (oInput.lBuffer[0] != '')
				next = oInput.lBuffer.shift()
				lLines.push next
			if (oInput.lBuffer.length == 0)
				throw new Error("""
						EOF while processing HEREDOC
						at line #{oInput.lineNum}
						n = #{n}
						""")
			oInput.lBuffer.shift()   # empty line
			lSections.push lLines
			n -= 1
		return patch(line, lSections)

	tester.equal 141, new StringInput("""
			x = 3

			str = <<<
			ghi

			jkl
			""", {mapper}), [
			'x = 3',
			'str = "ghi\\n"',
			'jkl',
			]

	tester.fails 154, new StringInput("""
			x = 3

			str = <<<
			ghi
			jkl
			""",
			{mapper})

	# --- test multiple HEREDOCs

	tester.equal 165, new StringInput("""
			x = 3

			str = compare(<<<, <<<)
			ghi

			jkl
			xyz

			say "OK"
			""", {mapper}), [
			'x = 3',
			'str = compare("ghi\\n", "jkl\\nxyz\\n")'
			'say "OK"',
			]
	)()

# ---------------------------------------------------------------------------
# --- Test mapping to objects

(()->

	cmdRE = ///^
			\s*                # skip leading whitespace
			\# ([a-z][a-z_]*)  # command name
			\s*                # skipwhitespace following command
			(.*)               # command arguments
			$///

	mapper = (line, oInput) ->
		lMatches = line.match(cmdRE)
		if lMatches?
			return { cmd: lMatches[1], argstr: lMatches[2] }
		else
			return line

	tester.equal 201, new StringInput("""
			abc
			#if x==y
				def
			#else
				ghi
			""", {mapper}), [
			'abc',
			{ cmd: 'if', argstr: 'x==y' },
			'\tdef',
			{ cmd: 'else', argstr: '' },
			'\tghi'
			]
	)()

# ---------------------------------------------------------------------------
# --- Test handling TAML HEREDOC

(()->

	mapper = (line, oInput) ->
		if line == '' || line.match(/^\s*#\s/)
			return undef     # skip comments and blank lines
		n = numHereDocs(line)
		if (n == 0)
			return line
		lSections = []     # --- will have one subarray for each HEREDOC
		while (n > 0)
			lLines = []
			while (oInput.lBuffer.length > 0) && (oInput.lBuffer[0] != '')
				next = oInput.lBuffer.shift()
				lLines.push next
			if (oInput.lBuffer.length == 0)
				throw new Error("""
						EOF while processing HEREDOC
						at line #{oInput.lineNum}
						n = #{n}
						""")
			oInput.lBuffer.shift()   # empty line
			lSections.push lLines
			n -= 1
		return patch(line, lSections)

	tester.equal 244, new StringInput("""
			x = 3

			str = compare(<<<, <<<, <<<)
				a multi
				line string

				---
					- first
					- second

				---
					name: John
					address: Blacksburg

			jkl
			""", {mapper}), [
			'x = 3',
			'str = compare("a multi\\nline string\\n", ["first","second"], {"name":"John","address":"Blacksburg"})',
			'jkl',
			]

	)()

# ---------------------------------------------------------------------------
# --- Test continuation lines

(()->

	mapper = (line, oInput) ->
		if line == '' || line.match(/^\s*#\s/)
			return undef     # skip comments and blank lines

		n = indentLevel(line)    # current line indent
		while (oInput.lBuffer.length > 0) && (indentLevel(oInput.lBuffer[0]) >= n+2)
			next = oInput.lBuffer.shift()
			line += ' ' + undentedStr(next)
		return line

	tester.equal 283, new StringInput("""
			str = compare(
					"abcde",
					expected
					)

			call func
					with multiple
					long parameters

			# --- DONE ---
			""", {mapper}), [
			'str = compare( "abcde", expected )',
			'call func with multiple long parameters',
			]

	)()

# ---------------------------------------------------------------------------
# --- Test continuation lines AND HEREDOCs

(()->

	mapper = (line, oInput) ->
		if line == '' || line.match(/^\s*#\s/)
			return undef     # skip comments and blank lines

		n = indentLevel(line)    # current line indent
		while (oInput.lBuffer.length > 0) && (indentLevel(oInput.lBuffer[0]) >= n+2)
			next = oInput.lBuffer.shift()
			line += ' ' + undentedStr(next)
		return line

	tester.equal 316, new StringInput("""
			str = compare(
					"abcde",
					expected
					)

			call func
					with multiple
					long parameters

			# --- DONE ---
			""", {mapper}), [
			'str = compare( "abcde", expected )',
			'call func with multiple long parameters',
			]

	)()

# ---------------------------------------------------------------------------
# --- Test prefix option

tester.equal 337, new StringInput("""
		abc
		def
		""", {prefix: '...'}), [
		'...abc',
		'...def',
		]

# ---------------------------------------------------------------------------
# --- Test #include

(()->

	tester.equal 350, new StringInput("""
			div
				#include title.md
			hr
			""", {
			hIncludePaths: {
				".md": markdownDir,
				}
			}), [
			'div'
			'\ttitle'
			'\t====='
			'hr'
			]
	)()
