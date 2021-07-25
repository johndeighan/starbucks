# Output.coffee

import fs from 'fs'
import {strict as assert} from 'assert'
import pathlib from 'path'
import Mustache from 'mustache'
import {config} from './starbucks.config.js'
import {
	sep_dash,
	dumpOutput,
	isString,
	error,
	say,
	undef,
	words,
	stringToArray,
	unitTesting,
	} from '@jdeighan/coffee-utils'
import {
	indentedBlock,
	indentedStr,
	} from '@jdeighan/coffee-utils/indent'
import {brewCoffee} from './brewCoffee.js'

# --- disable all escaping in Mustache
Mustache.escape = (text) -> text

# ---------------------------------------------------------------------------
#    exporting variable stdImportStr simplifies unit testing

utilsPath  = "#{config.libDir}/coffee_utils.js"
strStdSymbols = words("undef say ask isEmpty nonEmpty").join(',')
export stdImportStr = \
	"import {#{strStdSymbols}} from '#{utilsPath}';"

# ---------------------------------------------------------------------------

export class Output

	constructor: (@filename='unit test', logger=undef) ->
		@logging = logger?
		# --- We always want to set a logger, even if logging is false
		#     because logging could be turned on at any point
		@logger = logger || console.log

		if not @logger instanceof Function
			error "logger is not a function"

		# --- if desired, this must be set using method doDump()
		@dumping = false

		@hConsts = { FILE: @filename }
		@lLines = []

	# --- set a constant

	setConst: (name, val) ->
		@hConsts[name] = val.toString()
		return

	# --- turn logging on or off

	doLog: (flag, logger=undefined) ->
		@logging = flag
		if flag
			if logger?
				@logger = logger
			@log sep_dash, @filename, sep_dash
		return

	# --- turn dumping on or off

	doDump: (flag) ->
		@dumping = flag
		return

	put: (line, level=0) ->
		@lLines.push indentedStr(line, level)
		return

	get: () ->
		return @lLines.join('\n') + '\n'

	getLines: () ->
		return @lLines

	# --- log something

	log: (...lArgs) ->
		if @logging && @logger
			for arg in lArgs
				@logger arg
		return

# ---------------------------------------------------------------------------

export class StarbucksOutput extends Output

	constructor: (filename='unit test', logger=undef) ->
		super filename, logger

		@lPreStartup = []
		@lPreHtml = []
		@lPreScript = []

		@lStartup = []
		@lHtml = []
		@lScript = []
		@lStyle = []

		@lComponents = []
		@lVars = []

	# --- add a line of text to one of the
	#     output arrays

	hasSection: (section) ->
		switch section
			when 'html'
				@lHtml.length > 0
			when 'startup'
				@lStartup.length > 0
			when 'script'
				@lScript.length > 0
			when 'style'
				@lStyle.length > 0
			else
				error "Invalid section: #{section}"

	# --- declare a found component
	#     results in 'import <name> from <componentsDir>/<name>.svelte;'

	# TODO: search for file <name>.svelte or <name>.starbucks

	addComponent: (name) ->
		if @lComponents.includes(name)
			return
		@log "   Component #{name} found"

		dir = config.componentsDir
		path = "#{dir}/#{name}.starbucks"

		# --- Check if file exists, unless we're unit testing
		if not unitTesting
			if not fs.existsSync(path)
				path = "#{dir}/#{name}.svelte"
				if not fs.existsSync(path)
					path = pathlib.resolve(path)
					error "No such component: #{name} in #{dir}"

		@preScript "import #{name} from '#{path}';"
		@lComponents.push name

	addVar: (name) ->
		if @lVars.includes(name)
			return
		@log "   JS Variable #{name} found"
		@lVars.push name

	_addToSection: (lSection, text, level=0) ->
		text = Mustache.render(text, @hConsts)
		lSection.push indentedBlock(text, level)
		return

	put: (line, level=0) ->
		@_addToSection @lHtml, line, level
		return

	putScript: (text, level=0) ->
		@_addToSection @lScript, text, level
		return

	# --- set a JavaScript variable
	#     for now, only support strings

	putJSVar: (name, text, level=0) ->
		assert isString(text)
		@putScript "#{name} = \"\"\"", level
		@putScript text, level+2
		@putScript "\"\"\"", level+2
		return

	putStartup: (line, level=0) ->
		@_addToSection @lStartup, line, level
		return

	putStyle: (line, level=0) ->
		@_addToSection @lStyle, line, level
		return

	preHtml: (line, level=0) ->
		@_addToSection @lPreHtml, line, level
		return

	preScript: (line, level=1) ->
		@_addToSection @lPreScript, line, level
		return

	preStartup: (line, level=1) ->
		@_addToSection @lPreStartup, line, level
		return

	get: () ->

		if @filename=='index.starbucks'
			say "get() from index.starbucks"
			say this

		# --- This becomes an array of parts, which will
		#     be joined at the end

		lParts = []

		strPreStartup = @lPreStartup.join('\n')
		strStartup    = @lStartup.join('\n')
		if strPreStartup || strStartup
			lParts.push '<script context="module">'
			lParts.push brewCoffee(strStartup, strPreStartup)
			lParts.push '</script>', ''

		strPreHtml = @lPreHtml.join('\n')
		strHtml    = @lHtml.join('\n')
		if strPreHtml || strHtml
			if strPreHtml
				lParts.push strPreHtml
			if strHtml
				lParts.push strHtml

		strPreScript  = @lPreScript.join('\n')
		strScript     = @lScript.join('\n')
		if strPreScript || strScript || (@lVars.length  > 0)
			lParts.push '', '<script>'

			# --- import standard symbols
			lParts.push indentedStr(stdImportStr, 1)

			if (@lVars.length > 0)
				# --- set all variables to undefined
				for name in @lVars
					str = "var #{name} = undef;"
					lParts.push indentedStr(str, 1)

			lParts.push brewCoffee(strScript, strPreScript)
			lParts.push '</script>', ''

		strStyle    = @lStyle.join('\n')
		if strStyle
			lParts.push '', '<style>'
			lParts.push strStyle
			lParts.push '</style>', ''

		strFinal = lParts.join('\n')
		if @dumping
			dumpOutput strFinal, "FINAL OUTPUT for #{@filename}:"

		return strFinal

	getLines: () ->

		return stringToArray(@get())
