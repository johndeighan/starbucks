# sassify.coffee

import sass from 'sass'
import {say, undef} from '@jdeighan/coffee-utils'
import {procContent} from './StringInput.js'

disabled = false

# ---------------------------------------------------------------------------

export disableSassify = () ->

	disabled = true

# ---------------------------------------------------------------------------

SassMapper = (line, oInput) ->

	if line.match(/^\s*$/) || line.match(/^\s*#\s/)
		return undef
	return line

# ---------------------------------------------------------------------------

export sassify = (text) ->

	mapped = procContent(text, SassMapper)
	if disabled
		return mapped
	result = sass.renderSync({
			data: mapped,
			indentedSyntax: true,
			indentType: "tab",
			})
	return result.css.toString()
