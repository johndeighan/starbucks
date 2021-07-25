# 08StringInput.test.coffee

import {say, undef} from '../coffee_utils.js'
import {indentLevel, undentedStr} from '../indent_utils.js'
import {numHereDocs, patch} from '../heredoc_utils.js'
import {StringInput} from '../StringInput.js'
import {AvaTester} from 'ava-tester'
import {init} from './test_init.js'

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

tester.equal 30, new StringInput("""
		abc
		def
		"""), [
		'abc',
		'def',
		]

tester.equal 38, new StringInput("""
		abc

		def
		"""), [
		'abc',
		'',
		'def',
		]

tester.equal 48, new StringInput("""
		abc

		def
		""", undef,
		(line) ->
			if line == ''
				return undef
			else
				return line
		), [
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

	tester.equal 74, new StringInput("""
			abc

			def
			""", undef, mapper), [
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

	tester.equal 98, new StringInput("""
			abc

			def
			ghi
			""", undef, mapper), [
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

	tester.equal 138, new StringInput("""
			x = 3

			str = <<<
			ghi

			jkl
			""", undef, mapper), [
			'x = 3',
			'str = "ghi\\n"',
			'jkl',
			]

	tester.fails 151, new StringInput("""
			x = 3

			str = <<<
			ghi
			jkl
			""",
			undef, mapper)

	# --- test multiple HEREDOCs

	tester.equal 162, new StringInput("""
			x = 3

			str = compare(<<<, <<<)
			ghi

			jkl
			xyz

			say "OK"
			""", undef, mapper), [
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

	tester.equal 199, new StringInput("""
			abc
			#if x==y
				def
			#else
				ghi
			""", undef, mapper), [
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

	tester.equal 243, new StringInput("""
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
			""", undef, mapper), [
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
			""", undef, mapper), [
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

	tester.equal 317, new StringInput("""
			str = compare(
					"abcde",
					expected
					)

			call func
					with multiple
					long parameters

			# --- DONE ---
			""", undef, mapper), [
			'str = compare( "abcde", expected )',
			'call func with multiple long parameters',
			]

	)()
