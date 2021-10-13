// Generated by CoffeeScript 2.6.1
  // DataStores.coffee
import {
  strict as assert
} from 'assert';

import {
  writable,
  readable,
  get
} from 'svelte/store';

import {
  undef,
  pass,
  error,
  localStore,
  isEmpty
} from '@jdeighan/coffee-utils';

import {
  log
} from '@jdeighan/coffee-utils/log';

import {
  hPrivEnv
} from '@jdeighan/coffee-utils/privenv';

import {
  loadPrivEnvFrom
} from '@jdeighan/env';

import {
  getFileContents
} from '@jdeighan/string-input';

// ---------------------------------------------------------------------------
export var WritableDataStore = class WritableDataStore {
  constructor(value = undef) {
    this.store = writable(value);
  }

  subscribe(callback) {
    return this.store.subscribe(callback);
  }

  set(value) {
    return this.store.set(value);
  }

  update(func) {
    return this.store.update(func);
  }

};

// ---------------------------------------------------------------------------
export var LocalStorageDataStore = class LocalStorageDataStore extends WritableDataStore {
  constructor(masterKey1, defValue = undef) {
    var value;
    super(defValue);
    this.masterKey = masterKey1;
    value = localStore(this.masterKey);
    if (value != null) {
      this.set(value);
    }
  }

  // --- I'm assuming that when update() is called,
  //     set() will also be called
  set(value) {
    if (value == null) {
      error("LocalStorageStore.set(): cannont set to undef");
    }
    super.set(value);
    return localStore(this.masterKey, value);
  }

  update(func) {
    super.update(func);
    return localStore(this.masterKey, get(this.store));
  }

};

// ---------------------------------------------------------------------------
export var PropsDataStore = class PropsDataStore extends LocalStorageDataStore {
  constructor(masterKey) {
    super(masterKey, {});
  }

  setProp(name, value) {
    if (name == null) {
      error("PropStore.setProp(): empty key");
    }
    return this.update(function(hPrefs) {
      hPrefs[name] = value;
      return hPrefs;
    });
  }

};

// ---------------------------------------------------------------------------
export var ReadableDataStore = class ReadableDataStore {
  constructor() {
    this.store = readable(null, function(set) {
      this.setter = set; // store the setter function
      this.start(); // call your start() method
      return () => {
        return this.stop(); // return function capable of stopping
      };
    });
  }

  subscribe(callback) {
    return this.store.subscribe(callback);
  }

  start() {
    return pass;
  }

  stop() {
    return pass;
  }

};

// ---------------------------------------------------------------------------
export var DateTimeDataStore = class DateTimeDataStore extends ReadableDataStore {
  start() {
    // --- We need to store this interval for use in stop() later
    return this.interval = setInterval(function() {
      return this.setter(new Date(), 1000);
    });
  }

  stop() {
    return clearInterval(this.interval);
  }

};

// ---------------------------------------------------------------------------
export var MousePosDataStore = class MousePosDataStore extends ReadableDataStore {
  start() {
    // --- We need to store this handler for use in stop() later
    this.mouseMoveHandler = function(e) {
      return this.setter({
        x: e.clientX,
        y: e.clientY
      });
    };
    return document.body.addEventListener('mousemove', this.mouseMoveHandler);
  }

  stop() {
    return document.body.removeEventListener('mousemove', this.mouseMoveHandler);
  }

};

// ---------------------------------------------------------------------------
export var TAMLDataStore = class TAMLDataStore extends WritableDataStore {
  constructor(fname) {
    var data;
    assert(fname.match(/\.taml$/), "TAMLDataStore: fname must end in .taml");
    if (isEmpty(hPrivEnv) && (process.env.DIR_ROOT != null)) {
      log("private env is empty - loading");
      loadPrivEnvFrom(process.env.DIR_ROOT);
    }
    data = getFileContents(fname);
    super(data);
  }

};
