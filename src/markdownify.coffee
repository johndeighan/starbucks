# markdownify.coffee

import {strict as assert} from 'assert'
import marked from 'marked'

import {say, undef, unitTesting} from '@jdeighan/coffee-utils'
import {slurp} from '@jdeighan/coffee-utils/fs'
import {undentedBlock} from '@jdeighan/coffee-utils/indent'
import {procContent} from '@jdeighan/string-input'
import {svelteHtmlEsc} from '../src/svelte_utils.js'

# ---------------------------------------------------------------------------

export markdownify = (text) ->

	if unitTesting
		return text
	html = marked(undentedBlock(text), {
			grm: true,
			headerIds: false,
			})
	return svelteHtmlEsc(html)

# ---------------------------------------------------------------------------

export markdownifyFile = (filepath) ->

	text = slurp(filepath)
	return markdownify(text)
