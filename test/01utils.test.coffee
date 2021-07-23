# utils.test.coffee

import test from 'ava'
import {
	isTAML,
	taml,
	normalize,
	isEmpty,
	nonEmpty,
	words,
	escapeStr,
	truncateBlock,
	} from '../coffee_utils.js'
import {withExt} from '../fs_utils.js'
import {TruthyTester} from './test_utils.js'

# ---------------------------------------------------------------------------

tester = new TruthyTester()

# ---------------------------------------------------------------------------

# test "isEmpty 1", (t) -> t.truthy isEmpty('')
# test "isEmpty 2", (t) -> t.truthy isEmpty('  \t\t')
# test "isEmpty 3", (t) -> t.truthy isEmpty([])
# test "isEmpty 4", (t) -> t.truthy isEmpty({})

tester.test 28, isEmpty('')
tester.test 29, isEmpty('  \t\t')
tester.test 30, isEmpty([])
tester.test 31, isEmpty({})

tester.test 33, nonEmpty('a')
tester.test 34, nonEmpty('.')
tester.test 35, nonEmpty([2])
tester.test 36, nonEmpty({width: 2})

# ---------------------------------------------------------------------------

test "isTAML 1", (t) ->
	t.truthy isTAML "---\n- first\n- second"

# ---------------------------------------------------------------------------

test "isTAML 2", (t) ->
	t.falsy isTAML "x---\n"

# ---------------------------------------------------------------------------

test "TAML array", (t) ->
	result = taml("---\n- a\n- b")
	t.deepEqual result, ['a','b']

# ---------------------------------------------------------------------------

test "normalize 1", (t) ->
	t.is normalize("""
			line 1
			line 2
			"""), """
			line 1
			line 2
			""" + '\n'

test "normalize 2", (t) ->
	t.is normalize("""
			line 1

			line 2
			"""), """
			line 1
			line 2
			""" + '\n'

test "normalize 3", (t) ->
	t.is normalize("""

			line 1

			line 2


			"""), """
			line 1
			line 2
			""" + '\n'

test "words 1", (t) ->
	t.deepEqual words('a b c'), ['a', 'b', 'c']

test "words 2", (t) ->
	t.deepEqual words('  a   b   c  '), ['a', 'b', 'c']

# ---------------------------------------------------------------------------

test "withExt 1", (t) ->
	t.is withExt('file.starbucks', 'svelte'), 'file.svelte'

# ---------------------------------------------------------------------------

test "escapeStr 1", (t) ->
	t.is escapeStr("\t\tXXX\n"), "\\t\\tXXX\\n"

# ---------------------------------------------------------------------------

test "truncateBlock", (t) ->
	t.is truncateBlock("""
			line 1
			line 2
			line 3
			line 4
			""", 2), """
			line 1
			line 2
			""" + '\n'
