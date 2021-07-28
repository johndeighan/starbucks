# starbucks.config.coffee

import {strict as assert} from 'assert'
import fs from 'fs'
import process from 'process'
import dotenv from 'dotenv'

dotenv.config()

rootDir = process.env.ROOT
assert fs.existsSync(rootDir), "dir #{rootDir} doesn't exist"
srcDir = "#{rootDir}/src"
assert fs.existsSync(srcDir), "dir #{srcDir} doesn't exist"

export config = {
	rootDir
	componentsDir: "#{srcDir}/components"
	markdownDir:   "#{srcDir}/markdown"
	storesDir:     "#{srcDir}/stores"
	libDir:        "#{srcDir}/lib"
	dumpDir:       "#{rootDir}/dump"
	hConstants:
		companyName: "WayForward Technologies, Inc."
	}
