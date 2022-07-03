# starbucks.coffee

import pathlib from 'path'
import fs from 'fs'

import {
	assert, pass, undef, defined, error, words, escapeStr,
	isEmpty, isString, isHash, oneline, sep_eq, sep_dash,
	} from '@jdeighan/coffee-utils'
import {log, LOG} from '@jdeighan/coffee-utils/log'
import {debug, setDebugging} from '@jdeighan/coffee-utils/debug'
import {undented} from '@jdeighan/coffee-utils/indent'
import {svelteSourceCodeEsc} from '@jdeighan/coffee-utils/svelte'
import {
	slurp, barf, withExt, mydir, mkpath, newerDestFileExists,
	parseSource,
	} from '@jdeighan/coffee-utils/fs'
import {doMap} from '@jdeighan/mapper'
import {markdownify} from '@jdeighan/mapper/markdown'
import {isTAML, taml} from '@jdeighan/mapper/taml'
import {SvelteOutput} from '@jdeighan/svelte-output'
import {parsetag, attrStr, tag2str} from '@jdeighan/mapper/parsetag'

import {StarbucksTreeWalker} from '@jdeighan/starbucks/walker'

# ---------------------------------------------------------------------------

export starbucks = ({content, filename}, hOptions={}) ->

	debug "enter starbucks()"

	if ! content? || (content.length==0)
		result = {code: '', map: null}
		debug "return from starbucks()", result
		return result

	assert filename, "starbucks(): missing path/url"
	process.env['cielo.SOURCECODE'] = svelteSourceCodeEsc(content)

	code = doMap(StarbucksTreeWalker, filename, content)
	# --- If a webpage && there are parameters && no startup section
	#     then we need to generate a load() function

	result = {
		code,
		map: null,
		}
	debug "return from starbucks()", result
	return result

# ---------------------------------------------------------------------------
#       UTILITIES
# ---------------------------------------------------------------------------

export brewStarbucksStr = (starbucksCode, srcPath=undef) ->
	# --- starbucks => svelte

	hParsed = pathlib.parse(srcPath)
	hOptions = {
		content: starbucksCode,
		filename: hParsed.base,
		}
	h = starbucks(hOptions)
	return h.code

# ---------------------------------------------------------------------------

export brewStarbucksFile = (srcPath, destPath=undef, hOptions={}) ->
	# --- starbucks => svelte
	#     Valid Options:
	#        force

	if ! destPath?
		destPath = withExt(srcPath, '.svelte', {removeLeadingUnderScore:true})
	if hOptions.force || ! newerDestFileExists(srcPath, destPath)
		starbucksCode = slurp(srcPath)
		debug sep_eq
		debug starbucksCode
		debug sep_eq

		hParsed = pathlib.parse(srcPath)
		svelteCode = brewStarbucksStr(starbucksCode, hParsed.base)
		debug svelteCode
		debug sep_eq
		barf destPath, svelteCode
	return

# ---------------------------------------------------------------------------

