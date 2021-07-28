# brewCoffee.coffee

import CoffeeScript from 'coffeescript'
import {say, undef, pass, error} from '@jdeighan/coffee-utils'
import {
	splitLine,
	indentedStr,
	indentedBlock,
	} from '@jdeighan/coffee-utils/indent'
import {procContent} from '@jdeighan/string-input'

disabled = false

# ---------------------------------------------------------------------------

export disableBrewing = () ->

	disabled = true

# ---------------------------------------------------------------------------
# export only to allow unit testing

export CoffeeMapper = (orgLine, oInput) ->

	[level, line] = splitLine(orgLine)
	if (line == '') || line.match(/^#\s/)
		return undef
	if lMatches = line.match(///^
			(?:
				([A-Za-z][A-Za-z0-9_]*)   # variable name
				\s*
				)?
			\<\=\=
			\s*
			(.*)
			$///)
		[_, varname, expr] = lMatches
		if expr
			# --- convert to JavaScript ---
			try
				jsExpr = brewCoffee(expr).trim()   # will have trailing ';'
			catch err
				error err.message

			if varname
				result = indentedStr("\`\$\: #{varname} = #{jsExpr}\`", level)
			else
				result = indentedStr("\`\$\: #{jsExpr}\`", level)

			return result
		else
			if varname
				error "Invalid syntax - variable name not allowed"
			code = oInput.fetchBlock(level+1)
			try
				jsCode = brewCoffee(code).trim()
			catch err
				error err.message

			result = """
					\`\`\`
					\$\: {
					#{indentedBlock(jsCode, 1)}
					#{indentedStr('}', 1)}
					\`\`\`
					"""
			return indentedBlock(result, level)
	return orgLine

# ---------------------------------------------------------------------------
# If js is provided, it's escaped with ``` before converting

export brewCoffee = (text, js='') ->

	mapped = procContent(text, CoffeeMapper)
	if js
		mapped = """
			\t```
			#{js}
			\t```
			#{mapped}
			"""
	if disabled
		return mapped
	try
		script = CoffeeScript.compile(mapped, {bare: true})
	catch err
		say "CoffeeScript error in:"
		say mapped
		error "CoffeeScript error: #{err.message}"
	return script
