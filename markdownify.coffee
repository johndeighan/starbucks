# markdownify.coffee

import {strict as assert} from 'assert'
import marked from 'marked'
import {config} from './starbucks.config.js'
import {say, undef} from './coffee_utils.js'
import {slurp} from './fs_utils.js'
import {undentedBlock} from './indent_utils.js'
import {procContent} from './StringInput.js'

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
