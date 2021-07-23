# heredoc.test.coffee

import test from 'ava'
import {numHereDocs, patch, build} from '../heredoc_utils.js'

# ---------------------------------------------------------------------------

test "line 8", (t) ->
	t.is numHereDocs("where <<"), 0

# ---------------------------------------------------------------------------

test "line 13", (t) ->
	t.is numHereDocs("where <<<"), 1

# ---------------------------------------------------------------------------

test "line 18", (t) ->
	t.is numHereDocs("where <<< is <<<"), 2

# ---------------------------------------------------------------------------

test "line 23", (t) ->
	t.is numHereDocs("where <<< is <<< or <<<"), 3

# ---------------------------------------------------------------------------

test "line 28", (t) ->
	t.is(
		build([
				'a multi',
				'line string',
				]),
		"a multi\nline string\n"
		)

# ---------------------------------------------------------------------------

test "line 39", (t) ->
	t.is(
		patch("let x = <<<;", [[
				'a multi',
				'line string',
				]]),
		"let x = \"a multi\\nline string\\n\";"
		)

# ---------------------------------------------------------------------------

test "line 50", (t) ->
	t.is(
		build([
				'\t\ta multi',
				'\t\tline string',
				]),
		"a multi\nline string\n"
		)

# ---------------------------------------------------------------------------

test "line 61", (t) ->
	t.is(
		patch("let x = <<<; let y = <<<;", [[
				'\t\ta multi',
				'\t\tline string',
				],[
				'\ta new',
				'\tstring',
				]]),
		"let x = \"a multi\\nline string\\n\"; let y = \"a new\\nstring\\n\";"
		)

# ---------------------------------------------------------------------------

test "line 75", (t) ->
	t.is(build(undefined), '')

test "line 78", (t) ->
	t.is(build(null), '')

test "line 81", (t) ->
	t.is(build([]), '')

# --- build standard HEREDOC

test "line 86", (t) ->
	t.is(
		build([
			'first line',
			'second line',
			]),
		"first line\nsecond line\n"
		)

# --- TAML

test "line 97", (t) ->
	t.deepEqual(
		build(['---', '- first', '- second']),
		['first', 'second'],
		)

test "line 103", (t) ->
	t.deepEqual(
		build(['---', 'key: first', 'value: second']),
		{key: "first", value: "second"},
		)

# ---------------------------------------------------------------------------

test "line 111", (t) ->
	t.is(
		patch("let lItems = <<<;", [[
			'---',
			'- one',
			'- two',
			]]),
		'let lItems = ["one","two"];'
		)

# ---------------------------------------------------------------------------

test "line 123", (t) ->
	t.is(
		patch("let lItems = <<<;", [[
			'---',
			'key: one',
			'value: two',
			]]),
		'let lItems = {"key":"one","value":"two"};'
		)
