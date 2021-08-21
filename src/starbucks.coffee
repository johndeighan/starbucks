# starbucks.coffee

import {strict as assert} from 'assert'
import pathlib from 'path'
import fs from 'fs'

import {loadEnvFrom} from '@jdeighan/env'
import {
	say, pass, undef, error, dumpOutput, words, escapeStr,
	isEmpty, isString, isHash, isTAML, taml, oneline,
	} from '@jdeighan/coffee-utils'
import {debug, debugging, setDebugging} from '@jdeighan/coffee-utils/debug'
import {undentedBlock} from '@jdeighan/coffee-utils/indent'
import {svelteSourceCodeEsc} from '@jdeighan/coffee-utils/svelte'
import {barf, withExt, mydir} from '@jdeighan/coffee-utils/fs'
import {markdownify} from '@jdeighan/convert-utils'
import {SvelteOutput} from '@jdeighan/svelte-output'
import {foundCmd, endCmd} from './starbucks_commands.js'
import {StarbucksParser, attrStr, tag2str} from './StarbucksParser.js'
import {StarbucksTreeWalker} from './StarbucksTreeWalker.js'

hNoEnd = {}
for tag in words('area base br col command embed hr img input' \
		+ ' keygen link meta param source track wbr')
	hNoEnd[tag] = true

loadEnvFrom(mydir(`import.meta.url`))

# ---------------------------------------------------------------------------

export starbucks = ({content, filename}, hOptions={}) ->
	# --- Valid options:
	#        dumpDir

	assert content? && (content.length > 0), "starbucks(): empty content"
	assert isHash(hOptions), "starbucks(): arg 2 should be a hash"

	dumping = false
	if hOptions? && hOptions.dumpDir && filename?
		try
			fname = pathlib.parse(filename).base
			if fname
				dumppath = "#{hOptions.dumpDir}/#{withExt(fname, 'svelte')}"
				if fs.existsSync(dumppath)
					fs.unlinkSync(dumppath)
				dumping = true
			else
				fname = 'bad.name'
		catch e
			say e, "ERROR:"
	else if not filename?
		filename = 'unit test'

	filename = pathlib.parse(filename).base

	oOutput = new SvelteOutput(filename, hOptions)
	process.env.SOURCECODE = svelteSourceCodeEsc(content)

	fileKind = undef
	lPageParms = undef

	# ---  parser callbacks - must have access to oOutput object
	hHooks = {

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
							dir = process.env.DIR_STORES
							for str in value.split(/\s*,\s*/)
								if lMatches = str.match(/^(.*)\.(.*)$/)
									[_, stub, name] = lMatches
									path = "#{dir}/#{stub}.js"
									oOutput.putImport "import {#{name}} from '#{path}'"
								else
									path = "#{dir}/stores.js"
									oOutput.putImport "import {#{str}} from '#{path}'"
						when 'keyhandler'
							oOutput.put "<svelte:window on:keydown={#{value}}/>"
						else
							error "Unknown option: #{name}"
			return

		start_cmd: (cmd, argstr, level) ->
			foundCmd cmd, argstr, level, oOutput
			return

		end_cmd: (cmd, level) ->
			endCmd cmd, level, oOutput
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
							oOutput.declareJSVar lMatches[1]

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
				oOutput.putImport "import {onMount, onDestroy} from 'svelte'"
				onMountImported = true

			oOutput.putScript "onMount () => ", 1
			oOutput.putScript text, 2
			return

		ondestroy: (text, level) ->
			if not onMountImported
				oOutput.putImport "import {onMount, onDestroy} from 'svelte'"
				onMountImported = true

			oOutput.putScript "onDestroy () => ", 1
			oOutput.putScript text, 2
			return

		script: (text, level) ->
			oOutput.putScript text, level+1
			return

		style: (text, level) ->
			oOutput.putStyle text, level
			return

		pre: (hTag, level) ->
			text = hTag.containedText
			tag = tag2str(hTag)
			text = undentedBlock(text)
			oOutput.put "#{tag}#{text}</pre>"
			return

		markdown: (hTag, level) ->
			oOutput.put tag2str(hTag)
			oOutput.put markdownify(hTag.blockText), level
			oOutput.put "</div>"
			return

		sourcecode: (level) ->
			oOutput.put "<pre class=\"sourcecode\">#{content}</pre>", level
			return

		chars: (text, level) ->
			oOutput.put text, level
			return

		linenum: (lineNum) ->
			process.env.LINE = lineNum
			return
		}

	patchCallback = (lLines) ->

		str = undentedBlock(lLines)
		if isTAML(str)
			value = taml(str)
		else
			value = str
		varName = oOutput.setAnonVar(value)
		return varName

	parser = new StarbucksParser(content, oOutput)
	tree = parser.getTree()

	if debugging
		say tree, 'TREE:'

	walker = new StarbucksTreeWalker(hHooks)
	walker.walk(tree)

	# --- If a webpage && there are parameters && no startup section
	#     then we need to generate a load() function

	if (fileKind == 'webpage') && lPageParms?
		if not oOutput.hasSection('startup')
			oOutput.putStartup("""
				export function load({page}) {
					return { props: {#{lPageParms.join(',')}}};
					}
				""")

	if debugging
		say oOutput, "\noOutput:"

	code = oOutput.get()
	if dumping
		barf dumppath, code
	return {
		code,
		map: null,
		}
