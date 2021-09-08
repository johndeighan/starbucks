# starbucks.coffee

import {strict as assert} from 'assert'
import pathlib from 'path'
import fs from 'fs'

import {loadEnvFrom} from '@jdeighan/env'
import {
	say, log, pass, undef, error, words, escapeStr, arrayToString,
	isEmpty, isString, isHash, oneline, unitTesting,
	} from '@jdeighan/coffee-utils'
import {
	debug, debugging, startDebugging,
	} from '@jdeighan/coffee-utils/debug'
import {undented} from '@jdeighan/coffee-utils/indent'
import {svelteSourceCodeEsc} from '@jdeighan/coffee-utils/svelte'
import {barf, withExt, mydir, mkpath} from '@jdeighan/coffee-utils/fs'
import {markdownify, isTAML, taml} from '@jdeighan/string-input/convert'
import {SvelteOutput} from '@jdeighan/svelte-output'
import {StarbucksParser, attrStr, tag2str} from '@jdeighan/starbucks/parser'
import {StarbucksTreeWalker} from '@jdeighan/starbucks/walker'
import {foundCmd, endCmd} from './starbucks_commands.js'

hNoEnd = {}
for tag in words('area base br col command embed hr img input' \
		+ ' keygen link meta param source track wbr')
	hNoEnd[tag] = true

export env = loadEnvFrom(mydir(`import.meta.url`), {
	rootName: 'dir_root',
	})

# ---------------------------------------------------------------------------

getDumpPath = (fname) ->
	# --- fname is just a simple file name (no path)

	if not fname || not (dir = process.env.dir_dump)
		return undef
	if not fs.existsSync(dir)
		fs.mkdir(dir)
	dumppath = mkpath(dir, withExt(fname, 'svelte'))
	if fs.existsSync(dumppath)
		fs.unlinkSync(dumppath)
	return dumppath

# ---------------------------------------------------------------------------

export starbucks = ({content, filename}, hOptions={}) ->

	if not content? || (content.length==0)
		return {code: '', map: null}

	# --- filename is actually a full path!!!
	if filename
		fpath = filename
		fname = pathlib.parse(filename).base

	# --- if dumppath is set, then the resulting svelte output will be
	#     written to that file
	dumppath = getDumpPath(fname)

	if not fname?
		if unitTesting
			fname = 'unit test'
		else
			fname = 'unknown'

	oOutput = new SvelteOutput(fname, hOptions)
	process.env.SOURCECODE = svelteSourceCodeEsc(content)

	fileKind = undef
	lPageParms = undef

	# ---  parser callbacks - must have access to oOutput object
	hHooks = {

		header: (kind, lParms, optionstr) ->

			fileKind = kind
			debug "HOOK header: KIND = #{kind}"
			if lParms?
				debug "HOOK header: PARMS #{lParms.join(', ')}"
				if kind == 'component'
					for parm in lParms
						oOutput.putScript "export #{parm} = undef"
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
					debug "HOOK header: OPTION #{name} = #{value}"
					switch name
						when 'log'
							oOutput.doLog value
						when 'debug'
							startDebugging()
						when 'store', 'stores'
							dir = process.env.dir_stores
							assert dir, "please set env var 'dir_stores'"
							assert fs.existsSync(dir), "dir #{dir} doesn't exist"
							for str in value.split(/\s*,\s*/)
								if lMatches = str.match(/^(.*)\.(.*)$/)
									[_, stub, name] = lMatches
									path = "#{dir}/#{stub}.js"
									oOutput.addImport "import {#{name}} from '#{path}'"
								else
									path = "#{dir}/stores.js"
									oOutput.addImport "import {#{str}} from '#{path}'"
						when 'keyhandler'
							oOutput.putLine "<svelte:window on:keydown={#{value}}/>"
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
				oOutput.putLine "<#{tag}>", level
			else
				str = attrStr(hAttr)
				oOutput.putLine "<#{tag}#{str}>", level

				# --- Look for attributes like 'bind:value={name}'
				#     and auto-declare the variable inside { and }
				for own key, hValue of hAttr
					{value, quote} = hValue
					if key.match(///^
							bind
							\:
							[A-Za-z][A-Za-z0-9_]*
							$///)
						if (quote=='{') \
								&& value.match(/^([A-Za-z][A-Za-z0-9_]*)$/)
							oOutput.declareJSVar value

			if tag.match(/^[A-Z]/)
				oOutput.addComponent tag
			return

		end_tag: (tag, level) ->
			if not hNoEnd[tag]?
				oOutput.putLine "</#{tag}>", level
			return

		startup: (text, level) ->
			oOutput.putStartup  text, level+1
			return

		onmount: (text, level) ->
			oOutput.putScript "onMount () => "
			oOutput.putScript text, 1
			return

		ondestroy: (text, level) ->
			oOutput.putScript "onDestroy () => "
			oOutput.putScript text, 1
			return

		script: (text, level) ->
			oOutput.putScript text, level
			return

		style: (text, level) ->
			oOutput.putStyle text, level
			return

		pre: (hTag, level) ->
			text = hTag.containedText
			tag = tag2str(hTag)
			text = undented(text)
			oOutput.putLine "#{tag}#{text}</pre>"
			return

		markdown: (hTag, level) ->
			oOutput.putLine tag2str(hTag)
			oOutput.putLine markdownify(hTag.blockText), level
			oOutput.putLine "</div>"
			return

		sourcecode: (level) ->
			oOutput.putLine "<pre class=\"sourcecode\">#{content}</pre>", level
			return

		chars: (text, level) ->
			debug "enter HOOK chars '#{escapeStr(text)}' at level #{level}"
			assert oOutput instanceof SvelteOutput, "oOutput not a SvelteOutput"
			oOutput.putLine(text, level)
			debug "return from HOOK chars"
			return

		linenum: (lineNum) ->
			process.env.LINE = lineNum
			return
		}

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
				export load = ({page}) ->
					return {props: {#{lPageParms.join(',')}}}
				""")

	if debugging
		say oOutput, "\noOutput:"

	code = oOutput.get()
	if dumppath
		barf dumppath, code
	return {
		code,
		map: null,
		}
