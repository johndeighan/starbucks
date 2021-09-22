// Generated by CoffeeScript 2.6.0
  // starbucks.coffee
var getDumpPath, hNoEnd, i, len, ref, tag,
  hasProp = {}.hasOwnProperty;

import {
  strict as assert
} from 'assert';

import pathlib from 'path';

import fs from 'fs';

import {
  loadEnvFrom
} from '@jdeighan/env';

import {
  say,
  pass,
  undef,
  error,
  words,
  escapeStr,
  isEmpty,
  isString,
  isHash,
  oneline
} from '@jdeighan/coffee-utils';

import {
  debug,
  debugging,
  setDebugging
} from '@jdeighan/coffee-utils/debug';

import {
  undented
} from '@jdeighan/coffee-utils/indent';

import {
  svelteSourceCodeEsc
} from '@jdeighan/coffee-utils/svelte';

import {
  barf,
  withExt,
  mydir,
  mkpath
} from '@jdeighan/coffee-utils/fs';

import {
  markdownify
} from '@jdeighan/string-input/markdown';

import {
  isTAML,
  taml
} from '@jdeighan/string-input/taml';

import {
  SvelteOutput
} from '@jdeighan/svelte-output';

import {
  StarbucksParser,
  attrStr,
  tag2str
} from '@jdeighan/starbucks/parser';

import {
  StarbucksTreeWalker
} from '@jdeighan/starbucks/walker';

import {
  foundCmd,
  endCmd
} from './starbucks_commands.js';

hNoEnd = {};

ref = words('area base br col command embed hr img input' + ' keygen link meta param source track wbr');
for (i = 0, len = ref.length; i < len; i++) {
  tag = ref[i];
  hNoEnd[tag] = true;
}

loadEnvFrom(mydir(import.meta.url));

// ---------------------------------------------------------------------------
getDumpPath = function(fname) {
  var dir, dumppath;
  // --- fname is just a simple file name (no path)
  if (!fname || !(dir = process.env.dir_dump)) {
    return undef;
  }
  if (!fs.existsSync(dir)) {
    fs.mkdir(dir);
  }
  dumppath = mkpath(dir, withExt(fname, 'svelte'));
  if (fs.existsSync(dumppath)) {
    fs.unlinkSync(dumppath);
  }
  return dumppath;
};

// ---------------------------------------------------------------------------
export var starbucks = function({content, filename}, hOptions = {}) {
  var code, dumppath, fileKind, fname, fpath, hHooks, lPageParms, oOutput, parser, tree, walker;
  if ((content == null) || (content.length === 0)) {
    return {
      code: '',
      map: null
    };
  }
  // --- filename is actually a full path!!!
  if (filename) {
    fpath = filename;
    fname = pathlib.parse(filename).base;
  }
  // --- if dumppath is set, then the resulting svelte output will be
  //     written to that file
  dumppath = getDumpPath(fname);
  if (fname == null) {
    fname = 'unit test';
  }
  oOutput = new SvelteOutput(fname, hOptions);
  process.env.SOURCECODE = svelteSourceCodeEsc(content);
  fileKind = undef;
  lPageParms = undef;
  // ---  parser callbacks - must have access to oOutput object
  hHooks = {
    header: function(kind, lParms, optionstr) {
      var _, dir, j, k, l, lMatches, len1, len2, len3, name, opt, parm, path, ref1, ref2, str, stub, value;
      fileKind = kind;
      debug(`HOOK header: KIND = ${kind}`);
      if (lParms != null) {
        debug(`HOOK header: PARMS ${lParms.join(', ')}`);
        if (kind === 'component') {
          for (j = 0, len1 = lParms.length; j < len1; j++) {
            parm = lParms[j];
            oOutput.putScript(`export ${parm} = undef`);
          }
        } else {
          // -- parameters in kind == 'webpage' is handled at end
          //    because if the content has a 'startup' section, nothing
          //    is output, but if there isn't, we need to create it
          lPageParms = lParms;
        }
      }
      if (optionstr) {
        ref1 = optionstr.split(/\s+/);
        for (k = 0, len2 = ref1.length; k < len2; k++) {
          opt = ref1[k];
          [name, value] = opt.split(/=/, 2);
          if (value === '') {
            value = '1';
          }
          debug(`HOOK header: OPTION ${name} = ${value}`);
          switch (name) {
            case 'log':
              oOutput.doLog(value);
              break;
            case 'debug':
              setDebugging(true);
              break;
            case 'store':
            case 'stores':
              dir = process.env.dir_stores;
              assert(dir, "please set env var 'dir_stores'");
              assert(fs.existsSync(dir), `dir ${dir} doesn't exist`);
              ref2 = value.split(/\s*,\s*/);
              for (l = 0, len3 = ref2.length; l < len3; l++) {
                str = ref2[l];
                if (lMatches = str.match(/^(.*)\.(.*)$/)) {
                  [_, stub, name] = lMatches;
                  path = `${dir}/${stub}.js`;
                  oOutput.addImport(`import {${name}} from '${path}'`);
                } else {
                  path = `${dir}/stores.js`;
                  oOutput.addImport(`import {${str}} from '${path}'`);
                }
              }
              break;
            case 'keyhandler':
              oOutput.putLine(`<svelte:window on:keydown={${value}}/>`);
              break;
            default:
              error(`Unknown option: ${name}`);
          }
        }
      }
    },
    start_cmd: function(cmd, argstr, level) {
      foundCmd(cmd, argstr, level, oOutput);
    },
    end_cmd: function(cmd, level) {
      endCmd(cmd, level, oOutput);
    },
    start_tag: function(tag, hAttr, level) {
      var hValue, key, quote, str, value;
      if (isEmpty(hAttr)) {
        oOutput.putLine(`<${tag}>`, level);
      } else {
        str = attrStr(hAttr);
        oOutput.putLine(`<${tag}${str}>`, level);
        for (key in hAttr) {
          if (!hasProp.call(hAttr, key)) continue;
          hValue = hAttr[key];
          ({value, quote} = hValue);
          if (key.match(/^bind\:[A-Za-z][A-Za-z0-9_]*$/)) {
            if ((quote === '{') && value.match(/^([A-Za-z][A-Za-z0-9_]*)$/)) {
              oOutput.declareJSVar(value);
            }
          }
        }
      }
      if (tag.match(/^[A-Z]/)) {
        oOutput.addComponent(tag);
      }
    },
    end_tag: function(tag, level) {
      if (hNoEnd[tag] == null) {
        oOutput.putLine(`</${tag}>`, level);
      }
    },
    startup: function(text, level) {
      oOutput.putStartup(text, level + 1);
    },
    onmount: function(text, level) {
      oOutput.putScript("onMount () => ");
      oOutput.putScript(text, 1);
    },
    ondestroy: function(text, level) {
      oOutput.putScript("onDestroy () => ");
      oOutput.putScript(text, 1);
    },
    script: function(text, level) {
      oOutput.putScript(text, level);
    },
    style: function(text, level) {
      oOutput.putStyle(text, level);
    },
    pre: function(hTag, level) {
      var text;
      text = hTag.containedText;
      tag = tag2str(hTag);
      text = undented(text);
      oOutput.putLine(`${tag}${text}</pre>`);
    },
    markdown: function(hTag, level) {
      oOutput.putLine(tag2str(hTag));
      oOutput.putLine(markdownify(hTag.blockText), level);
      oOutput.putLine("</div>");
    },
    sourcecode: function(level) {
      oOutput.putLine(`<pre class=\"sourcecode\">${content}</pre>`, level);
    },
    chars: function(text, level) {
      debug(`enter HOOK_chars '${escapeStr(text)}' at level ${level}`);
      assert(oOutput instanceof SvelteOutput, "oOutput not a SvelteOutput");
      oOutput.putLine(text, level);
      debug("return from HOOK_chars");
    },
    linenum: function(lineNum) {
      process.env.LINE = lineNum;
    }
  };
  parser = new StarbucksParser(content, oOutput);
  tree = parser.getTree();
  if (debugging) {
    say(tree, 'TREE:');
  }
  walker = new StarbucksTreeWalker(hHooks);
  walker.walk(tree);
  // --- If a webpage && there are parameters && no startup section
  //     then we need to generate a load() function
  if ((fileKind === 'webpage') && (lPageParms != null)) {
    if (!oOutput.hasSection('startup')) {
      oOutput.putStartup(`export load = ({page}) ->
	return {props: {${lPageParms.join(',')}}}`);
    }
  }
  if (debugging) {
    say(oOutput, "\noOutput:");
  }
  code = oOutput.get();
  if (dumppath) {
    barf(dumppath, code);
  }
  return {
    code,
    map: null
  };
};
