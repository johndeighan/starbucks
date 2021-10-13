# MediaQueries.coffee

import {undef} from '@jdeighan/coffee-utils'
import {log} from '@jdeighan/coffee-utils/log'
import {debug} from '@jdeighan/coffee-utils/debug'
import {hPrivEnv} from '@jdeighan/coffee-utils/privenv'

mediaQueriesLoaded = false

# ---------------------------------------------------------------------------

interpret = (str) ->

	if lMatches = str.match(///^
			(.*)                  # pre text
			size \s*              # word 'size'
			\(
			(\d+)                 # width lower bound
			\.\.
			(\d+ | inf) \s*       # width upper bound
			(?:
				, \s*
				(\d+)              # height lower bound
				\.\.
				(\d+ | inf) \s*    # height upper bound
				)?
			(in | px | mm | cm)   # units
			\)
			(.*)                  # post text
			$///)
		[_, pre, wLow, wHigh, hLow, hHigh, units, post] = lMatches
		lParts = []

		if (wLow > 0)
			lParts.push "(min-device-width: #{wLow}#{units})"
		if (wHigh != 'inf')
			lParts.push "(max-device-width: #{wHigh}#{units})"
		if hLow?
			if (hLow > 0)
				lParts.push "(min-device-height: #{hLow}#{units})"
			if (hHigh != 'inf')
				lParts.push "(max-device-height: #{hHigh}#{units})"
		else
			# --- No heights specified, so use widths
			if (wLow > 0)
				lParts.push "(min-device-height: #{wLow}#{units})"
			if (wHigh != 'inf')
				lParts.push "(max-device-height: #{wHigh}#{units})"
		result = lParts.join(' and ')
		return "#{pre}#{result}#{post}"
	else
		return str

# ---------------------------------------------------------------------------
# export to allow unit tests

# --- defaults
export hMediaQueries = {
	mobile: interpret("screen and size(0..6 in)"),
	tablet: interpret("screen and size(6..12 in)"),
	other: interpret("screen and size(12..inf in)"),
	}

# ---------------------------------------------------------------------------
# export to allow unit tests

export loadMediaQueries = () ->

	debug "enter loadMediaQueries()"
	for key,query of hPrivEnv
		if lMatches = key.match(/^MEDIA_(.*)$/i)
			name = lMatches[1].toLowerCase()
			debug "found media query for '#{name}' = #{query}"
			hMediaQueries[name] = interpret(query)
	mediaQueriesLoaded = true
	debug "return from loadMediaQueries()", hMediaQueries
	return

# ---------------------------------------------------------------------------

export getMediaQuery = (name) ->
	# --- returns undef if not a valid media query

	debug "enter getMediaQuery('#{name}')"
	if ! name
		# --- if name is undef or empty
		debug "return undef from getMediaQuery() - empty name"
		return undef
	if ! mediaQueriesLoaded
		loadMediaQueries()

	debug "hMediaQueries", hMediaQueries

	if hMediaQueries.hasOwnProperty(name)
		debug "return #{hMediaQueries[name]} from getMediaQuery()"
		return hMediaQueries[name]
	else
		debug "return undef from getMediaQuery()"
		return undef
