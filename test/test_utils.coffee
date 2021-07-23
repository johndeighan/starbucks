# test_utils.coffee

import {strict as assert} from 'assert'
import test from 'ava'
import {
	say,
	normalize,
	dumpOutput,
	escapeStr,
	undef,
	pass,
	stringToArray,
	deepCopy,
	error,
	nonEmpty,
	isHash,
	isArray,
	unitTesting,
	setUnitTesting,
	setDebugging,
	debug,
	} from '../coffee_utils.js'
import {splitLine} from '../indent_utils.js'
import {StringInput, SimpleMapper} from '../StringInput.js'
import {StarbucksMapper, StarbucksInput} from '../StarbucksInput.js'
import {starbucks} from '../starbucks.js'
import {StarbucksParser} from '../StarbucksParser.js'
import {StarbucksOutput} from '../Output.js'
import {parsetag, tag2str, attrStr} from '../parsetag.js'
import {foundCmd, finished} from '../starbucks_commands.js'
import {
	markdownify,
	disableMarkdown,
	enableMarkdown,
	} from '../markdownify.js'
import {disableBrewing} from '../brewCoffee.js'
import {disableSassify} from '../sassify.js'

setUnitTesting(true)

testing = true    # set false when negative lineNum encountered
justshow = false

disableBrewing()      # disable converting CoffeeScript to JavaScript
disableSassify()      # disable converting SASS to CSS
disableMarkdown()     # disable converting markdown to HTML

# ---------------------------------------------------------------------------

export class Tester

	# --- Use package globals: testing, justshow
	constructor: (whichTest='deepEqual') ->
		@hFound = {}
		@setWhichTest whichTest

	# ........................................................................

	setWhichTest: (testName) ->
		@whichTest = testName
		return

	# ........................................................................

	getValue: (input) ->
		error "Tester: you must override getValue()"

	# ........................................................................

	test: (lineNum, input, expected, just_show=false) ->

		if not testing
			return

		justshow = just_show

		lineNum = @getLineNum(lineNum)
		got = @getValue(input)

		# --- We need to save this here because in the tests themselves,
		#     'this' won't be correct
		whichTest = @whichTest

		if lineNum < 0
			if justshow
				say "line #{lineNum}"
				say got, "GOT:\n"
				say expected, "EXPECTED:\n"
			else
				test.only "line #{lineNum}", (t) ->
					t[whichTest] got, expected
			testing = false
		else
			test "line #{lineNum}", (t) ->
				t[whichTest] got, expected
		return

	# ........................................................................

	getLineNum: (lineNum) ->

		# --- patch lineNum to avoid duplicates
		while @hFound[lineNum]
			if lineNum < 0
				lineNum -= 1000
			else
				lineNum += 1000
		@hFound[lineNum] = true
		return lineNum

# ---------------------------------------------------------------------------

export class SimpleTester extends Tester

	constructor: (func, whichTest='deepEqual') ->
		super(whichTest)
		@setFunc(func)

	setFunc: (func) ->
		@func = func
		return

	getValue: (input) ->
		return @func(input)

# ---------------------------------------------------------------------------

export class TruthyTester extends Tester

	constructor: (func) ->
		super('truthy')

	getValue: (input) ->
		return input

# ---------------------------------------------------------------------------

export show_only = () ->

	justshow = true

# ---------------------------------------------------------------------------

export procLevel = (atLevel, oInput, oOutput) ->

	while hToken = oInput.peek()
		{level, line, lineNum, type, cmd, argstr} = hToken
		if (level > atLevel)
			procLevel level, oInput, oOutput
		else
			oInput.skip()
			switch type
				when 'cmd'
					foundCmd cmd, argstr, level, oOutput
				when 'text'
					oOutput.put indentedStr(line, level)
				when 'tag'
					oOutput.put line
				else
					error "procLevel(): empty type"
	return

# ---------------------------------------------------------------------------

export test_states = (lineNum, input, expected=undef) ->

	if not testing
		return
	lineNum = fix(lineNum)

	func = (str) ->
		oInput = new StarbucksInput(str)
		oOutput = new StarbucksOutput()
		text = procLevel(0, oInput, oOutput)
		if nonEmpty(text)
			oOutput.put(text)
		finished(oOutput)
		return oOutput.get()

	if justshow
		say "line #{lineNum}"
		try
			result = func(input)
			say result, "GOT:\n"
		catch err
			say "GOT ERROR"
		if expected
			say expected, "EXPECTED:\n"
		else
			say "EXPECTED ERROR\n"
	else if expected
		result = func(input)
		if lineNum < 0
			test.only "line #{lineNum}", (t) ->
				t.is normalize(result), normalize(expected)
			testing = false
		else
			test "line #{lineNum}", (t) ->
				t.is normalize(result), normalize(expected)
	else

# ---------------------------------------------------------------------------

export test_markdown = (lineNum, text, expected) ->

	if not testing
		return
	lineNum = fix(lineNum)

	enableMarkdown()
	html = markdownify(text)
	disableMarkdown()

	if lineNum < 0
		if justshow
			say "line #{lineNum}"
			say html, "GOT:\n"
			say expected, "EXPECTED:\n"
		else
			test.only "line #{lineNum}", (t) ->
				t.is normalize(html), normalize(expected)
		testing = false
	else
		test "line #{lineNum}", (t) ->
			t.is normalize(html), normalize(expected)

# ---------------------------------------------------------------------------

export test_parser = (lineNum, content, expected) ->

	if not testing
		return
	lineNum = fix(lineNum)

	code = starbucks({content, 'unit test'}).code

	if lineNum < 0
		if justshow
			say "line #{lineNum}"
			say code, "GOT:\n"
			say expected, "EXPECTED:\n"
		else
			test.only "line #{lineNum}", (t) ->
				t.is normalize(code), normalize(expected)
		testing = false
	else
		test "line #{lineNum}", (t) ->
			t.is normalize(code), normalize(expected)

# ---------------------------------------------------------------------------

export test_callbacks = (lineNum, content, expected) ->

	if not testing
		return
	lineNum = fix(lineNum)

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

	parser = new StarbucksParser(hCallbacks)
	parser.parse(content, "unit test #{lineNum}")

	# --- Remove terminating newline from strTrace because
	#     CoffeeScript """ strings don't include it
	strTrace = strTrace.substring(0, strTrace.length - 1)

	if lineNum < 0
		if justshow
			say "line #{lineNum}"
			say strTrace, "GOT:\n"
			say expected, "EXPECTED:\n"
		else
			test.only "line #{lineNum}", (t) ->
				t.is normalize(strTrace), normalize(expected)
		testing = false
	else
		test "line #{lineNum}", (t) ->
			t.is normalize(strTrace), normalize(expected)

# ---------------------------------------------------------------------------

export test_starbucks = (lineNum, text, expected) ->

	if not testing
		return
	lineNum = fix(lineNum)

	lLogs = []    # array to hold logs
	h = starbucks({
		content: text,
		source: 'unit test',
		}, ((str) -> lLogs.push(str)), 'testing')
	if lineNum < 0
		if justshow
			say "line #{lineNum}"
			say h.code, "GOT:"
			say lLogs, "LOGS"
			say expected, "EXPECTED:"
		else
			test.only "line #{lineNum}", (t) ->
				t.is normalize(h.precode), normalize(expected)
		testing = false
	else
		test "line #{lineNum}", (t) ->
			t.is normalize(h.precode), normalize(expected)

# ---------------------------------------------------------------------------

normalizeContainedText = (hToken) ->

	assert isHash(hToken)
	if hToken.containedText?
		hToken.containedText = normalize(hToken.containedText)
	return

# ---------------------------------------------------------------------------
# if expected is undefined, we expect a thrown error

export test_token = (lineNum, content, expected, mapper=StarbucksMapper) ->

	if not testing
		return
	lineNum = fix(lineNum)

	oInput = new StarbucksInput(content)
	if isArray(expected)
		for hToken in expected
			normalizeContainedText(hToken)
		result = []
		while hToken = oInput.get()
			normalizeContainedText(hToken)
			result.push(hToken)
	else if isHash(expected)
		normalizeContainedText(expected)
		result = oInput.peek()
		normalizeContainedText(result)
	else
		error "test_token(): invalid expected value"

	if lineNum < 0
		if justshow
			say "line #{lineNum}"
			say result, "GOT:"
			say expected, "EXPECTED:"
		else
			test.only "line #{lineNum}", (t) ->
				t.deepEqual result, expected
		testing = false
	else
		test "line #{lineNum}", (t) ->
			t.deepEqual result, expected

# ---------------------------------------------------------------------------
# if expected is undefined, we expect a thrown error

export test_mapper = (lineNum, content, expected, mapper=StarbucksMapper) ->

	if not testing
		return
	lineNum = fix(lineNum)

	oInput = new StarbucksInput(content)
	line = oInput.fetch()
	result = mapper(line, oInput)

	if lineNum < 0
		if justshow
			say "line #{lineNum}"
			say result, "GOT:"
			say expected, "EXPECTED:"
		else
			if typeof result == 'string'
				test.only "line #{lineNum}", (t) ->
					t.is normalize(result), normalize(expected)
			else
				test.only "line #{lineNum}", (t) ->
					t.deepEqual result, expected
		testing = false
	else
		if typeof result == 'string'
			test "line #{lineNum}", (t) ->
				t.is normalize(result), normalize(expected)
		else
			test "line #{lineNum}", (t) ->
				t.deepEqual result, expected

# ---------------------------------------------------------------------------
# if expected is undefined, we expect a thrown error

export fails_mapper = (lineNum, text) ->

	if not testing
		return
	lineNum = fix(lineNum)

	lLines = stringToArray(text)
	if lLines.length == 0
		throw new Error("test_mapper(): text is empty")
	line = lLines.shift()

	if lineNum < 0
		if justshow
			say "line #{lineNum}"
			try
				result = StarbucksMapper(line, new StarbucksInput(lLines))
				result = 'SUCCEEDS'
			catch e
				result = 'FAILS'
			say "GOT: #{result}"
			say "EXPECTED: FAILS"
		else
			test.only "line #{lineNum}", (t) ->
				t.throws () -> StarbucksMapper(line, new StringInput(lLines))
		testing = false
	else
		test "line #{lineNum}", (t) ->
			t.throws () -> StarbucksMapper(line, new StringInput(lLines))

# ---------------------------------------------------------------------------

export stop_testing = () ->
	testing = false

# ---------------------------------------------------------------------------

export start_testing = () ->
	testing = true

# ---------------------------------------------------------------------------

export gather = (oInput, nLines=undef) ->

	if oInput not instanceof StringInput
		throw new Error("oInput should be a StringInput object")
	lLines = []
	if nLines?
		# --- get nLines lines
		for i in [1..nLines]
			lLines.push(oInput.get())
	else
		# --- get until EOF
		line = oInput.get()
		while line?
			lLines.push(line)
			line = oInput.get()
	return lLines

# ---------------------------------------------------------------------------

export test_gather = (lineNum, oInput, expected) ->

	if oInput not instanceof StringInput
		throw new Error("test_gather(): oInput must be instance of StringInput")

	if not testing
		return
	lineNum = fix(lineNum)

	if expected?
		lLines = gather(oInput)
		if lineNum < 0
			if justshow
				say "line #{lineNum}"
				say lLines, "GOT:"
				say expected, "EXPECTED:"
			else
				if expected?
					test.only "line #{lineNum}", (t) ->
						t.deepEqual lLines, expected
				else
					test.only "line #{lineNum}", (t) ->
						t.throws()
			testing = false
		else
			if expected?
				test "line #{lineNum}", (t) ->
					t.deepEqual lLines, expected
			else
				test "line #{lineNum}", (t) ->
					t.throws()
	else
		# --- if expected is undef, we expected an error

		if lineNum < 0

			failed = false
			try
				lLines = gather(oInput)
			catch e
				failed = true

			if justshow
				# --- Print out what we got
				if failed
					say "GOT FAILURE"
				else
					say "GOT THIS:"
					say lLines

				# --- Print out what we expected
				say "EXPECTED FAILURE"
			else
				test.only "line #{lineNum}", (t) ->
					t.throws () -> gather(oInput)
			testing = false
		else
			test "line #{lineNum}", (t) ->
				t.throws () -> gather(oInput)
	return

# ---------------------------------------------------------------------------

export test_output = (lineNum, oOutput, expected) ->

	if oOutput not instanceof StarbucksOutput
		error "test_output(): oOutput must be instance of StarbucksOutput"

	if not testing
		return
	lineNum = fix(lineNum)

	result = oOutput.get()

	if lineNum < 0
		if justshow
			say "line #{lineNum}"
			say result, "GOT THIS:"
			say expected, "EXPECTED THIS:"
		else
			test.only "line #{lineNum}", (t) ->
				t.is normalize(result), normalize(expected)
		testing = false
	else
		test "line #{lineNum}", (t) ->
			t.is normalize(result), normalize(expected)

# ---------------------------------------------------------------------------

hFound = {}    # already found line numbers

fix = (lineNum) ->

	while hFound[lineNum]
		if lineNum < 0
			lineNum -= 1000
		else
			lineNum += 1000
	hFound[lineNum] = true
	return lineNum
