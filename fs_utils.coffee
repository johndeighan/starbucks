# fs_utils.coffee

import fs from 'fs'
import {config} from './starbucks.config.js'
import {taml, undef, error, unitTesting} from './coffee_utils.js'

# ---------------------------------------------------------------------------
#   backup - back up a file

# --- If report is true, missing source files are not an error
#     but both missing source files and successful copies
#     are reported via console.log

export backup = (file, from, to, report=false) ->
	src = "#{from}/#{file}"
	dest = "#{to}/#{file}"

	if report
		if fs.existsSync(src)
			console.log "OK #{file}"
			fs.copyFileSync(src, dest)
		else
			console.log "MISSING #{src}"
	else
		fs.copyFileSync(src, dest)

# ---------------------------------------------------------------------------
#   slurp - read an entire file into a string

export slurp = (filepath) ->
	return fs.readFileSync(filepath, 'utf8').toString()

# ---------------------------------------------------------------------------
#   slurpTAML - read TAML from a file

export slurpTAML = (filepath) ->
	contents = slurp(filepath)
	return taml(contents)

# ---------------------------------------------------------------------------
#   barf - write a string to a file

export barf = (filepath, contents) ->
	fs.writeFileSync(filepath, contents, {encoding: 'utf8'})

# --- Capable of removing leading whitespace which is found on
#     the first line from all lines,
#     Can handle an array of strings or a multi-line string

# ---------------------------------------------------------------------------
#   withExt - change file extention in a file name

export withExt = (filename, newExt) ->

	if lMatches = filename.match(/^(.*)\.([A-Za-z]+)$/)
		[_, pre, ext] = lMatches
		return "#{pre}.#{newExt}"
	else
		error "withExt(): Invalid file name: '#{filename}'"

# ---------------------------------------------------------------------------

export getFileContents = (filename) ->

	if unitTesting
		return "Contents of #{filename}"
	else if lMatches = filename.match(///^
			(
				[A-Za-z0-9_\.]+  # base file name (i.e. stub)
				\.
				([a-z]+)         # file extension
				)
			$///)
		[_, filename, ext] = lMatches

		# --- get full path to file
		switch ext
			when 'md'
				fullpath = "#{config.markdownDir}/#{filename}"
			else
				error "#include #{filename} - unsupported file ext"

		return slurp(fullpath)

