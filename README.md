Ember Local Storage Decorator
==============================================================================

Decorator to use `localStorage` and `sessionStorage` in Ember.


Reactive localStorage and sessionStorage for Ember with multiple APIs to fit your needs.


## ✅ Compatibility

- Ember.js v5.12 or above
- Embroider or ember-auto-import v2


## 📦 Installation

```bash
pnpm install ember-local-storage-decorator
# or
yarn add ember-local-storage-decorator
# or
npm install ember-local-storage-decorator
```

## 🚀 Usage

This library provides three ways to work with browser storage in Ember:

### 1. TrackedStorage Class (Primitive)

The most flexible option - a tracked wrapper around the Web Storage API that works with both localStorage and sessionStorage. All operations are reactive and will trigger Ember's reactivity system.

This addon provides two decorators: `@localStorage` and `@sessionStorage`. 
Both work identically, the only difference is the backing storage used. 
`@localStorage` persists data in `window.localStorage` available across browser 
sessions, while `@sessionStorage` persists data in `window.sessionStorage` only for 
the duration of the current page session.

```js
import { localStorage, sessionStorage } from 'ember-local-storage-decorator';
import Component from '@glimmer/component';

export default class MyComponent extends Component {
  @localStorage foo;
  @sessionStorage bar;
}
```

Decorate a class property with `@localStorage` or `@sessionStorage` to bind it 
to the respective storage. It will attach a getter to read the value from storage 
and a setter to write changes to storage.

```js
const Klass = class {
  @localStorage foo;
  @sessionStorage bar;
}
const klass = new Klass();

klass.foo = 'baz';
window.localStorage.getItem('foo'); // '"baz"'

klass.bar = 'qux';
window.sessionStorage.getItem('bar'); // '"qux"'
```

You may specify another key to be used in storage as an argument to the
decorator.

```js
const Klass = class {
  @localStorage('bar') foo;
  @sessionStorage('baz') qux;
};
const klass = new Klass();

klass.foo = 'baz';
window.localStorage.getItem('bar'); // '"baz"'

klass.qux = 'quux';
window.sessionStorage.getItem('baz'); // '"quux"'
```

The value is stored as a JSON string in storage. Therefore only values
which can be serialized to JSON are supported.

The `@sessionStorage` decorator works identically to `@localStorage` but uses sessionStorage instead:

```js
const Klass = class {
  @sessionStorage tempData;
};
```

### Default Values
You can provide a default value that will be used if no value exists in storage:

```js
const Klass = class {
  @localStorage foo = 'defaultValue';
  @sessionStorage bar = { count: 0 };
};
```

Due to limitations of the Web Storage API, direct changes to the storage 
bypassing the decorator can not be observed. Therefore you _should not_
manipulate `window.localStorage` or `window.sessionStorage` directly.

All three approaches share these characteristics:

`window.localStorage` and `window.sessionStorage` are global state, which is shared between test runs.
The decorators use a global cache, which is also shared between instances.
Both are not reset automatically between test jobs.

To avoid leaking state between test jobs it's recommended to clear the cache
of `@localStorage` and `@sessionStorage` decorators before each test. 
`clearLocalStorageCache` and `clearSessionStorageCache` helper functions are 
exported from `ember-local-storage-decorator` to do so.

Additionally `window.localStorage` and `window.sessionStorage` should be either 
cleared before each test run or mocked.

```js
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { clearLocalStorageCache, clearSessionStorageCache } from 'ember-local-storage-decorator';

module('Integration | Component | my-component', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    clearLocalStorageCache();
    clearSessionStorageCache();
    window.localStorage.clear();
    window.sessionStorage.clear();
  });
});
```

`@localStorage` and `@sessionStorage` decorators perform some initialization 
work when a property is decorated. This includes picking up the current value 
from local storage or session storage and adding it to its internal cache. 
Manual changes to local storage or session storage _after_ a property has been 
decorated are _not_ picked up. As class instances are often shared between test 
jobs, you need to manual reinitialize a local storage or session storage key 
in tests.

```js
import { initializeLocalStorageKey, initializeSessionStorageKey } from 'ember-local-storage-decorator';

test('some code relying on a value in local storage', function() {
  // Manually set a value in storage
  window.localStorage.setItem('__tracked_storage__:foo', JSON.stringify('bar'));
  
  // Reinitialize the key so the decorator picks up the change
  initializeLocalStorageKey('foo');
});

test('some code relying on a value in session storage', function() {
  window.sessionStorage.setItem('foo', 'bar');
  initializeSessionStorageKey('foo');
});
```

Note: When manually setting values in storage for testing, remember to use the prefixed key format and JSON-stringify the value. The `DEFAULT_PREFIX` constant is exported to make this easier:

```js
import { DEFAULT_PREFIX, initializeLocalStorageKey } from 'ember-local-storage-decorator';

test('some code relying on a value in local storage', function() {
  window.localStorage.setItem(`${DEFAULT_PREFIX}:foo`, JSON.stringify('bar'));
  initializeLocalStorageKey('foo');
});

test('some code relying on a value in session storage', function() {
  window.sessionStorage.setItem('foo', 'bar');
  initializeSessionStorageKey('foo');
});
```

## 🤝 Contributing

See the [Contributing](CONTRIBUTING.md) guide for details.


## 📄 License

This project is licensed under the [MIT License](LICENSE.md).
