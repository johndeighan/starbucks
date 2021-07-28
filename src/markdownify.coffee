# markdownify.coffee

import {strict as assert} from 'assert'
import marked from 'marked'
import {config} from '../starbucks.config.js'
import {say, undef} from '@jdeighan/coffee-utils'
import {slurp} from '@jdeighan/coffee-utils/fs'
import {undentedBlock} from '@jdeighan/coffee-utils/indent'
import {procContent} from '@jdeighan/string-input'

disabled = false
export disableMarkdown = () -> disabled=true
export enableMarkdown  = () -> disabled=false

# ---------------------------------------------------------------------------

export markdownify = (text) ->

	if disabled
		return text
	html = marked(undentedBlock(text), {
			grm: true,
			headerIds: false,
			})
	return html

# ---------------------------------------------------------------------------

export markdownifyFile = (filename) ->

	fpath = "#{config.markdownDir}/#{filename}"
	text = slurp(fpath)
	html = markdownify(text)
	return html
