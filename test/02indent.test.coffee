# indent.test.coffee

import test from 'ava'
import {
	indentLevel,
	indentation,
	undentedStr,
	undentedBlock,
	splitLine,
	indentedStr,
	indentedBlock,
	} from '../indent_utils.js'

# ---------------------------------------------------------------------------

test "indentLevel 1", (t) ->
	t.is indentLevel("abc"), 0

test "indentLevel 2", (t) ->
	t.is indentLevel("\tabc"), 1

test "indentLevel 3", (t) ->
	t.is indentLevel("\t\tabc"), 2

# ---------------------------------------------------------------------------

test "indentation 1", (t) ->
	t.is indentation(0), ''

test "indentation 2", (t) ->
	t.is indentation(1), "\t"

test "indentation 3", (t) ->
	t.is indentation(2), "\t\t"

# ---------------------------------------------------------------------------

test "undentedStr 1", (t) ->
	t.is undentedStr("abc"), "abc"

test "undentedStr 2", (t) ->
	t.is undentedStr("\tabc"), "abc"

test "undentedStr 3", (t) ->
	t.is undentedStr("\t\tabc"), "abc"

test "undentedStr 4", (t) ->
	t.is undentedStr("\t\tabc", 0), "\t\tabc"

test "undentedStr 5", (t) ->
	t.is undentedStr("\t\tabc", 1), "\tabc"

test "undentedStr 6", (t) ->
	t.is undentedStr("\t\tabc", 2), "abc"

# ---------------------------------------------------------------------------

test "undentedBlock 1", (t) ->
	t.is(
		undentedBlock([
			"\t\tfirst",
			"\t\tsecond",
			"\t\t\tthird",
			]),
		"""
		first
		second
			third

		"""
		)

# ---------------------------------------------------------------------------

test "undentedBlock 2", (t) ->
	t.is(
		undentedBlock("\t\tfirst\n\t\tsecond\n\t\t\tthird\n"),
		"first\nsecond\n\tthird\n",
		)

# ---------------------------------------------------------------------------

test "splitLine 1", (t) ->
	t.deepEqual splitLine("abc"), [0, "abc"]

test "splitLine 2", (t) ->
	t.deepEqual splitLine("\tabc"), [1, "abc"]

test "splitLine 3", (t) ->
	t.deepEqual splitLine("\t\tabc"), [2, "abc"]

# ---------------------------------------------------------------------------

test "indentedStr 1", (t) ->
	t.is indentedStr("abc", 0), "abc"

test "indentedStr 2", (t) ->
	t.is indentedStr("abc", 1), "\tabc"

test "indentedStr 3", (t) ->
	t.is indentedStr("abc", 2), "\t\tabc"

# ---------------------------------------------------------------------------

