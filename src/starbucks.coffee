# starbucks.coffee

import {strict as assert} from 'assert'
import pathlib from 'path'
import fs from 'fs'
import dotenv from 'dotenv'
import {sassify} from './sassify.js'

import {markdownify} from './markdownify.js'
import {
	defined,
	say,
	pass,
	undef,
	error,
	dumpOutput,
	isEmpty,
	setDebugging,
	debug,
	} from '@jdeighan/coffee-utils'
import {svelteEsc} from './svelte_utils.js'
import {undentedBlock} from '@jdeighan/coffee-utils/indent'
import {barf, withExt} from '@jdeighan/coffee-utils/fs'
import {attrStr} from './parsetag.js'
import {StarbucksOutput} from './Output.js'
import {StarbucksParser} from './StarbucksParser.js'
import {config} from '../starbucks.config.js'
import {foundCmd, finished} from './starbucks_commands.js'

hNoEnd = {
	input: true,
	}

# ---------------------------------------------------------------------------

# --- This just returns the StarbucksOutput object

pre_starbucks = ({content, filename}, logger=undef) ->

	assert defined(content), "pre_starbucks(): undefined content"
	assert (content.length > 0), "StarbucksTester: empty content"
	hFileInfo = pathlib.parse(filename)
	filename = hFileInfo.base
	if logger?
		oOutput = new StarbucksOutput(filename, logger)
	else
		oOutput = new StarbucksOutput(filename)
	oOutput.setConst('SOURCECODE', svelteEsc(content))

	# --- Define app wide constants
	if config.hConstants?
		for name,value of config.hConstants
			oOutput.setConst(name, value)

	fileKind = undef
	lPageParms = undef

	# ---  parser callbacks  ---
	hCallbacks = {

		header: (kind, lParms, optionstr) ->

			fileKind = kind
			oOutput.log "   KIND = #{kind}"
			if lParms?
				oOutput.log "   PARMS #{lParms.join(', ')}"
				if kind == 'component'
					for parm in lParms
						oOutput.putScript "export #{parm} = undef", 1
				else
					# -- parameters in kind == 'webpage' is handled at end
					#    because if the content has a 'startup' section, nothing
					#    is output, but if there isn't, we need to create it
					lPageParms = lParms

			if optionstr
				for opt in optionstr.split(/\s+/)
					[name, value] = opt.split(/=/, 2)
					if value == ''
						value = '1'
					oOutput.log "   OPTION #{name} = #{value}"
					switch name
						when 'log'
							oOutput.doLog value
						when 'dump'
							oOutput.doDump value
						when 'debug'
							setDebugging(true)
						when 'store', 'stores'
							dir = config.storesDir
							for str in value.split(/\s*,\s*/)
								if lMatches = str.match(/^(.*)\.(.*)$/)
									[_, stub, name] = lMatches
									path = "#{dir}/#{stub}.js"
									oOutput.preScript "import {#{name}} from '#{path}';"
								else
									path = "#{dir}/stores.js"
									oOutput.preScript "import {#{str}} from '#{path}';"
						when 'keyhandler'
							oOutput.preHtml "<svelte:window on:keydown={#{value}}/>"
						else
							error "Unknown option: #{name}"
			return

		command: (cmd, argstr, level) ->
			foundCmd cmd, argstr, level, oOutput
			return

		start_tag: (tag, hAttr, level) ->
			if isEmpty(hAttr)
				oOutput.put "<#{tag}>", level
			else
				str = attrStr(hAttr)
				oOutput.put "<#{tag}#{str}>", level

				# --- Look for attributes like 'bind:value={name}'
				#     and auto-declare the variable inside { and }
				for own key,hValue of hAttr
					if key.match(///^
							bind
							\:
							[A-Za-z][A-Za-z0-9_]*
							$///)
						if lMatches = hValue.value.match(///^
								\{
								([A-Za-z][A-Za-z0-9_]*)
								\}
								$///)
							oOutput.addVar lMatches[1]

			if tag.match(/^[A-Z]/)
				oOutput.addComponent tag
			return

		end_tag: (tag, level) ->
			if not hNoEnd[tag]?
				oOutput.put "</#{tag}>", level
			return

		startup: (text, level) ->
			oOutput.putStartup  text, level+1
			return

		onmount: (text, level) ->
			if not onMountImported
				oOutput.preScript "import {onMount, onDestroy} from 'svelte';"
				onMountImported = true

			oOutput.putScript "onMount () => ", 1
			oOutput.putScript text, 2
			return

		ondestroy: (text, level) ->
			if not onMountImported
				oOutput.preScript "import {onMount, onDestroy} from 'svelte';"
				onMountImported = true

			oOutput.putScript "onDestroy () => ", 1
			oOutput.putScript text, 2
			return

		script: (text, level) ->
			oOutput.putScript text, level+1
			return

		style: (text, level) ->
			oOutput.putStyle sassify(text, oOutput.log), level
			return

		pre: (hToken, level) ->
			text = hToken.containedText
			tag = tag2str(hToken)
			text = undentedBlock(text)
			oOutput.put("#{tag}#{text}</pre>")
			return

		markdown: (text, level) ->
			oOutput.put markdownify(text), level
			return

		sourcecode: (level) ->
			oOutput.put "<pre class=\"sourcecode\">#{content}</pre>", level
			return

		chars: (text, level) ->
			oOutput.put text, level
			return

		linenum: (lineNum) ->
			oOutput.setConst 'LINE', lineNum
			return

		}

	parser = new StarbucksParser(hCallbacks)
	parser.parse(content, filename)

	finished(oOutput)

	# --- If a webpage && there are parameters && no startup section
	#     then we need to generate a load() function

	if (fileKind == 'webpage') && lPageParms?
		if not oOutput.hasSection('startup')
			oOutput.preStartup("""
				export function load({page}) {
					return { props: {#{lPageParms.join(',')}}};
					}
				""")

	return oOutput

# ---------------------------------------------------------------------------
# This is the real preprocessor, used in svelte.config.coffee
# ---------------------------------------------------------------------------

export starbucks = ({content, filename}, logger=undef) ->

	dotenv.config()

	if config.dumpDir && filename?
		try
			fname = pathlib.parse(filename).base
			if fname
				dumppath = "#{config.dumpDir}/#{withExt(fname, 'svelte')}"
				if fs.existsSync(dumppath)
					fs.unlinkSync(dumppath)
				dumping = true
			else
				fname = 'bad.name'
		catch e
			say e, "ERROR:"
	else
		dumping = false
		filename = 'unit test'

	oOutput = pre_starbucks({content, filename}, logger)
	code = oOutput.get()
	if dumping
		barf dumppath, code
	return {
		code,
		map: null,
		}

# ---------------------------------------------------------------------------
