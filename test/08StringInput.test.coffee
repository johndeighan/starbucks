# StringInput.test.coffee

import {say, undef} from '../coffee_utils.js'
import {indentLevel, undentedStr} from '../indent_utils.js'

import {StringInput} from '../StringInput.js'
import {numHereDocs, patch} from '../heredoc_utils.js'
import {test_gather, stop_testing} from './test_utils.js'

# ---------------------------------------------------------------------------

# --- Test basic reading till EOF

test_gather 19, new StringInput("""
		abc
		def
		"""), [
		'abc',
		'def',
		]

# ---------------------------------------------------------------------------

# --- Test basic use of mapping function

(()->
	test_gather 32, new StringInput("""
			abc

			def
			"""), [
			'abc',
			'',
			'def',
			]

	test_gather 42, new StringInput("""
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

	mapper = (line) ->
		if line == ''
			return undef
		else
			return 'x'

	test_gather 63, new StringInput("""
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

	test_gather 87, new StringInput("""
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
						at line #{oInput.line()}
						n = #{n}
						""")
			oInput.lBuffer.shift()   # empty line
			lSections.push lLines
			n -= 1
		return patch(line, lSections)

	test_gather 127, new StringInput("""
			x = 3

			str = <<<
			ghi

			jkl
			""", undef, mapper), [
			'x = 3',
			'str = "ghi\\n"',
			'jkl',
			]

	test_gather 140, new StringInput("""
			x = 3

			str = <<<
			ghi
			jkl
			""",
			undef, mapper), undef  # expect an exception

	# --- test multiple HEREDOCs

	test_gather 151, new StringInput("""
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

	test_gather 188, new StringInput("""
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
						at line #{oInput.line()}
						n = #{n}
						""")
			oInput.lBuffer.shift()   # empty line
			lSections.push lLines
			n -= 1
		return patch(line, lSections)

	test_gather 232, new StringInput("""
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

	test_gather 272, new StringInput("""
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

	test_gather 306, new StringInput("""
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
