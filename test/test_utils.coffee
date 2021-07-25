# test_utils.coffee

import {strict as assert} from 'assert'
import test from 'ava'
import {
	say,
	normalize,
	undef,
	isString,
	error,
	setUnitTesting,
	} from '../coffee_utils.js'
import {disableMarkdown} from '../markdownify.js'
import {disableBrewing} from '../brewCoffee.js'
import {disableSassify} from '../sassify.js'

# ---------------------------------------------------------------------------

export class AvaTester

	# --- Use package globals: testing
	constructor: (whichTest='deepEqual') ->
		@hFound = {}
		@setWhichTest whichTest
		@justshow = false
		@testing = true

	# ........................................................................

	setWhichTest: (testName) ->
		@whichTest = testName
		return

	# ........................................................................

	transformValue: (input) ->
		return input

	# ........................................................................

	truthy: (lineNum, input, expected, just_show=false) ->
		@setWhichTest 'truthy'
		@test lineNum, input, expected, just_show

	# ........................................................................

	falsy: (lineNum, input, expected, just_show=false) ->
		@setWhichTest 'falsy'
		@test lineNum, input, expected, just_show

	# ........................................................................

	equal: (lineNum, input, expected, just_show=false) ->
		@setWhichTest 'deepEqual'
		@test lineNum, input, expected, just_show

	# ........................................................................

	notequal: (lineNum, input, expected, just_show=false) ->
		@setWhichTest 'notDeepEqual'
		@test lineNum, input, expected, just_show

	# ........................................................................

	fails: (lineNum, input, expected, just_show=false) ->
		if (expected != undef)
			error "AvaTester.fails(): expected value not allowed"
		@setWhichTest 'throws'
		@test lineNum, input, expected, just_show

	# ........................................................................

	normalize: (input) ->

		if isString(input)
			return normalize(input)
		else
			return input

	# ........................................................................

	test: (lineNum, input, expected, just_show=false) ->

		setUnitTesting(true)
		disableBrewing()      # disable converting CoffeeScript to JavaScript
		disableSassify()      # disable converting SASS to CSS
		disableMarkdown()     # disable converting markdown to HTML

		if not @testing
			return

		@justshow = just_show

		lineNum = @getLineNum(lineNum)
		expected = @normalize(expected)

		# --- We need to save this here because in the tests themselves,
		#     'this' won't be correct
		whichTest = @whichTest

		if (whichTest == 'throws')
			if @justshow
				say "line #{lineNum}"
				try
					got = @transformValue(input)
					say result, "GOT:\n"
				catch err
					say "GOT ERROR"
				say "EXPECTED ERROR\n"
		else
			got = @normalize(@transformValue(input))
			if lineNum < 0
				if @justshow
					say "line #{lineNum}"
					say got, "GOT:\n"
					say expected, "EXPECTED:\n"
				else
					test.only "line #{lineNum}", (t) ->
						t[whichTest] got, expected
				@testing = false
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
