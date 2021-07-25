# test_init.coffee

import {strict as assert} from 'assert'
import test from 'ava'
import {setUnitTesting} from '../coffee_utils.js'
import {disableMarkdown} from '../markdownify.js'
import {disableBrewing} from '../brewCoffee.js'
import {disableSassify} from '../sassify.js'

export init = () ->
	setUnitTesting(true)
	disableMarkdown()
	disableBrewing()
	disableSassify()

init()
