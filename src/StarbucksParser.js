// Generated by CoffeeScript 2.5.1
  // StarbucksParser.coffee
import {
  strict as assert
} from 'assert';

import {
  say,
  pass,
  undef,
  error,
  sep_dash,
  words,
  unitTesting,
  isEmpty,
  setDebugging,
  debug
} from '@jdeighan/coffee-utils';

import {
  splitLine
} from '@jdeighan/coffee-utils/indent';

import {
  procContent
} from './StringInput.js';

import {
  StarbucksInput,
  isBlockTag,
  getFileContents
} from './StarbucksInput.js';

// ---------------------------------------------------------------------------
//   class StarbucksParser
export var StarbucksParser = class StarbucksParser {
  constructor(hCallbacks) {
    var i, key, len, ref;
    this.hCallbacks = hCallbacks;
    // --- Ensure all callbacks exist:
    //        header, start_tag, end_tag, command, chars,
    //        script, style, startup, onmount, ondestroy
    if (hCallbacks.chars == null) {
      hCallbacks.chars = pass;
    }
    if (hCallbacks.script == null) {
      hCallbacks.script = hCallbacks.chars;
    }
    if (hCallbacks.style == null) {
      hCallbacks.style = hCallbacks.chars;
    }
    if (hCallbacks.startup == null) {
      hCallbacks.startup = hCallbacks.chars;
    }
    if (hCallbacks.onmount == null) {
      hCallbacks.onmount = hCallbacks.chars;
    }
    if (hCallbacks.ondestroy == null) {
      hCallbacks.ondestroy = hCallbacks.chars;
    }
    ref = words(`header start_tag end_tag command comment linenum markdown`);
    for (i = 0, len = ref.length; i < len; i++) {
      key = ref[i];
      if (hCallbacks[key] == null) {
        hCallbacks[key] = pass;
      }
    }
  }

  // ........................................................................
  parse(content, filename) {
    this.content = content;
    this.filename = filename;
    this.oInput = new StarbucksInput(content, {filename});
    this.parseHeader();
    return this.parseBlock(0);
  }

  // ........................................................................
  callback(key, ...args) {
    return this.hCallbacks[key](...args);
  }

  // ........................................................................
  parseHeader() {
    var _, argstr, badHeaderMsg, cmd, hToken, kind, lMatches, level, optionstr, parms, type;
    hToken = this.oInput.get();
    badHeaderMsg = `Invalid #starbucks header in ${this.filename}`;
    assert.equal(typeof hToken, 'object', `${badHeaderMsg} - not an object`);
    ({type, level, cmd, argstr} = hToken);
    assert.equal(type, 'cmd', `${badHeaderMsg} - type '${type}' is not 'cmd'`);
    assert.equal(level, 0, `${badHeaderMsg} - level '${level}' is not 0`);
    assert.equal(cmd, 'starbucks', `${badHeaderMsg} - cmd '${cmd}' is not 'starbucks'`);
    assert(argstr, "#starbucks - missing type");
    lMatches = argstr.match(/^(webpage|component)\s*(?:\(([^\)]*)\)\s*)?(.*)\s*$/); // parameters
    // open paren
    // anything except ) - parameters to component
    // close paren
    // options
    // allow trailing whitespace
    assert(lMatches, badHeaderMsg);
    [_, kind, parms, optionstr] = lMatches;
    // --- if debugging, turn it on before calling debug()
    if (optionstr && optionstr.match(/\bdebug\b/)) {
      setDebugging(true);
    }
    debug("CALL parseHeader()");
    debug(hToken, "GOT TOKEN:");
    // --- expect:  {
    //        type: 'cmd',
    //        level: 0,
    //        cmd: 'starbucks',
    //        argstr: '<type> <options>',
    //        }
    if (parms) {
      return this.callback('header', kind, parms.trim().split(/\s*,\s*/), optionstr);
    } else {
      return this.callback('header', kind, undef, optionstr);
    }
  }

  // ........................................................................
  parseBlock(atLevel) {
    var argstr, blockText, cmd, containedText, hAttr, hToken, level, lineNum, skipComments, subtype, tag, text, type;
    debug(`CALL parseBlock(${atLevel})`);
    while (hToken = this.oInput.peek()) {
      debug(hToken, "TOKEN:");
      ({type, level, lineNum} = hToken);
      if (level < atLevel) {
        debug(`   next token at level ${level} - returning`);
        return;
      }
      // --- The mapper should have joined this line to the previous
      if (level > atLevel) {
        error(`Line ${lineNum} in ${this.filename} should be level ${atLevel} - it's at level ${level}`);
      }
      // --- consume the line (no need to assign it)
      this.oInput.get();
      this.callback('linenum', lineNum);
      switch (type) {
        case 'cmd':
          // --- Make a command callback
          ({cmd, argstr} = hToken);
          this.callback('command', cmd, argstr, level);
          // --- parse contained starbucks code
          this.parseBlock(level + 1);
          break;
        case 'tag':
          if (isBlockTag(hToken)) {
            ({tag, subtype, hAttr, containedText, blockText} = hToken);
            text = containedText || '';
            if (blockText) {
              text += blockText;
            }
            // --- We have to do this to prevent markdown like:
            //          # this is a heading
            //     being interpreted as a comment
            skipComments = (tag !== 'div') || (subtype !== 'markdown');
            text = this.procBlock(text, skipComments);
            switch (tag) {
              case 'script':
                switch (subtype) {
                  case 'startup':
                    this.callback('startup', text, level);
                    break;
                  case 'onmount':
                    this.callback('onmount', text, level);
                    break;
                  case 'ondestroy':
                    this.callback('ondestroy', text, level);
                    break;
                  default:
                    this.callback('script', text, level);
                }
                break;
              case 'style':
                this.callback('style', text, level);
                break;
              case 'pre':
                this.callback('pre', hToken, level);
                break;
              case 'div':
                this.callback('start_tag', 'div', hAttr, level);
                switch (subtype) {
                  case 'markdown':
                    this.callback('markdown', text, level + 1);
                    break;
                  case 'sourcecode':
                    this.callback('sourcecode', level + 1);
                    break;
                  default:
                    error(`Bad block tag: ${tag}:${subtype}`);
                }
                this.callback('end_tag', 'div', level); // non-block tag
            }
          } else {
            ({tag, subtype, hAttr, containedText} = hToken);
            // --- make a 'start_tag' callback
            this.callback('start_tag', tag, hAttr, level);
            // --- handle contained text
            if (containedText) {
              this.callback('chars', containedText, level + 1);
            }
            this.parseBlock(level + 1);
            // --- make an 'end_tag' callback
            this.callback('end_tag', tag, level);
          }
          break;
        case 'text':
          this.callback('chars', hToken.text, lineNum);
          break;
        default:
          error("Unknown token type");
      }
    }
    debug("   at EOF - returning");
  }

  // ........................................................................
  procBlock(text, skipComments) {
    var mapper;
    mapper = function(line, oInput) {
      var _, argstr, cmd, fileContents, lMatches, level, str;
      this.oInput = oInput;
      if (isEmpty(line)) {
        return undef; // skip empty lines
      }
      
        // --- line has indentation stripped off
      [level, str] = splitLine(line);
      if (lMatches = str.match(/^\#(\S*)\s*(.*)$/)) { // a command or comment
        [_, cmd, argstr] = lMatches;
        if (!cmd && skipComments) {
          return undef; // skip comments
        } else if (cmd === 'include') {
          fileContents = getFileContents(argstr);
          this.oInput.unfetch(fileContents);
          return undef;
        }
      }
      return line;
    };
    return procContent(text, mapper);
  }

};
