// Generated by CoffeeScript 2.5.1
  // starbucks.coffee
var env, hNoEnd, i, len, ref, tag,
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
  dumpOutput,
  words,
  escapeStr,
  isEmpty,
  isString,
  isHash,
  isTAML,
  taml,
  oneline
} from '@jdeighan/coffee-utils';

import {
  debug,
  debugging,
  setDebugging
} from '@jdeighan/coffee-utils/debug';

import {
  undentedBlock
} from '@jdeighan/coffee-utils/indent';

import {
  svelteSourceCodeEsc
} from '@jdeighan/coffee-utils/svelte';

import {
  barf,
  withExt,
  mydir
} from '@jdeighan/coffee-utils/fs';

import {
  markdownify
} from '@jdeighan/convert-utils';

import {
  SvelteOutput
} from '@jdeighan/svelte-output';

import {
  foundCmd,
  endCmd
} from './starbucks_commands.js';

import {
  StarbucksParser,
  attrStr,
  tag2str
} from './StarbucksParser.js';

import {
  StarbucksTreeWalker
} from './StarbucksTreeWalker.js';

hNoEnd = {};

ref = words('area base br col command embed hr img input' + ' keygen link meta param source track wbr');
for (i = 0, len = ref.length; i < len; i++) {
  tag = ref[i];
  hNoEnd[tag] = true;
}

env = loadEnvFrom(mydir(import.meta.url), {
  rootName: 'dir_root'
});

// ---------------------------------------------------------------------------
export var starbucks = function({content, filename}, hOptions = {}) {
  var code, dumping, dumppath, e, fileKind, fname, hHooks, lPageParms, oOutput, parser, patchCallback, tree, walker;
  // --- Valid options:
  //        dumpDir
  assert((content != null) && (content.length > 0), "starbucks(): empty content");
  assert(isHash(hOptions), "starbucks(): arg 2 should be a hash");
  dumping = false;
  if ((hOptions != null) && hOptions.dumpDir && (filename != null)) {
    try {
      fname = pathlib.parse(filename).base;
      if (fname) {
        dumppath = `${hOptions.dumpDir}/${withExt(fname, 'svelte')}`;
        if (fs.existsSync(dumppath)) {
          fs.unlinkSync(dumppath);
        }
        dumping = true;
      } else {
        fname = 'bad.name';
      }
    } catch (error1) {
      e = error1;
      say(e, "ERROR:");
    }
  } else if (filename == null) {
    filename = 'unit test';
  }
  filename = pathlib.parse(filename).base;
  oOutput = new SvelteOutput(filename, hOptions);
  process.env.SOURCECODE = svelteSourceCodeEsc(content);
  fileKind = undef;
  lPageParms = undef;
  // ---  parser callbacks - must have access to oOutput object
  hHooks = {
    header: function(kind, lParms, optionstr) {
      var _, dir, j, k, l, lMatches, len1, len2, len3, name, opt, parm, path, ref1, ref2, str, stub, value;
      fileKind = kind;
      oOutput.log(`   KIND = ${kind}`);
      if (lParms != null) {
        oOutput.log(`   PARMS ${lParms.join(', ')}`);
        if (kind === 'component') {
          for (j = 0, len1 = lParms.length; j < len1; j++) {
            parm = lParms[j];
            oOutput.putScript(`export ${parm} = undef`, 1);
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
          oOutput.log(`   OPTION ${name} = ${value}`);
          switch (name) {
            case 'log':
              oOutput.doLog(value);
              break;
            case 'dump':
              oOutput.doDump(value);
              break;
            case 'debug':
              setDebugging(true);
              break;
            case 'store':
            case 'stores':
              dir = process.env.DIR_STORES;
              ref2 = value.split(/\s*,\s*/);
              for (l = 0, len3 = ref2.length; l < len3; l++) {
                str = ref2[l];
                if (lMatches = str.match(/^(.*)\.(.*)$/)) {
                  [_, stub, name] = lMatches;
                  path = `${dir}/${stub}.js`;
                  oOutput.putImport(`import {${name}} from '${path}'`);
                } else {
                  path = `${dir}/stores.js`;
                  oOutput.putImport(`import {${str}} from '${path}'`);
                }
              }
              break;
            case 'keyhandler':
              oOutput.put(`<svelte:window on:keydown={${value}}/>`);
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
        oOutput.put(`<${tag}>`, level);
      } else {
        str = attrStr(hAttr);
        oOutput.put(`<${tag}${str}>`, level);
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
        oOutput.put(`</${tag}>`, level);
      }
    },
    startup: function(text, level) {
      oOutput.putStartup(text, level + 1);
    },
    onmount: function(text, level) {
      var onMountImported;
      if (!onMountImported) {
        oOutput.putImport("import {onMount, onDestroy} from 'svelte'");
        onMountImported = true;
      }
      oOutput.putScript("onMount () => ", 1);
      oOutput.putScript(text, 2);
    },
    ondestroy: function(text, level) {
      var onMountImported;
      if (!onMountImported) {
        oOutput.putImport("import {onMount, onDestroy} from 'svelte'");
        onMountImported = true;
      }
      oOutput.putScript("onDestroy () => ", 1);
      oOutput.putScript(text, 2);
    },
    script: function(text, level) {
      oOutput.putScript(text, level + 1);
    },
    style: function(text, level) {
      oOutput.putStyle(text, level);
    },
    pre: function(hTag, level) {
      var text;
      text = hTag.containedText;
      tag = tag2str(hTag);
      text = undentedBlock(text);
      oOutput.put(`${tag}${text}</pre>`);
    },
    markdown: function(hTag, level) {
      oOutput.put(tag2str(hTag));
      oOutput.put(markdownify(hTag.blockText), level);
      oOutput.put("</div>");
    },
    sourcecode: function(level) {
      oOutput.put(`<pre class=\"sourcecode\">${content}</pre>`, level);
    },
    chars: function(text, level) {
      oOutput.put(text, level);
    },
    linenum: function(lineNum) {
      process.env.LINE = lineNum;
    }
  };
  patchCallback = function(lLines) {
    var str, value, varName;
    str = undentedBlock(lLines);
    if (isTAML(str)) {
      value = taml(str);
    } else {
      value = str;
    }
    varName = oOutput.setAnonVar(value);
    return varName;
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
      oOutput.putStartup(`export function load({page}) {
	return { props: {${lPageParms.join(',')}}};
	}`);
    }
  }
  if (debugging) {
    say(oOutput, "\noOutput:");
  }
  code = oOutput.get();
  if (dumping) {
    barf(dumppath, code);
  }
  return {
    code,
    map: null
  };
};
