Ember Local Storage Decorator
==============================================================================

Decorator to use `localStorage` in Ember Octane.


Compatibility
------------------------------------------------------------------------------

- Ember.js v5.12 or above
- Embroider or ember-auto-import v2


Installation
------------------------------------------------------------------------------

```
ember install ember-local-storage-decorator
```

Usage
------------------------------------------------------------------------------

This addon provides two decorators: `@localStorage` and `@sessionStorage`. 
Both work identically, the only difference is the backing storage used. 
`@localStorage` persists data across browser sessions, while `@sessionStorage` 
only persists data for the duration of the page session.

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

Objects (and arrays) are deep frozen to avoid leaking state. Getter returns a
frozen copy after setting a value.

```js
window.localStorage.setItem('foo', [{ a: 'b' }]);

const Klass = class {
  @localStorage foo;
};
const klass = new Klass();

Object.isFrozen(klass.foo); // true
Object.isFrozen(klass.foo[0]); // true

const newValue = {};
klass.foo = newValue;

Object.isFrozen(klass.foo); // true
Object.isFrozen(newValue); // false
```

It observes changes caused by other classes or by other instances:

```js
const KlassA = class {
  @localStorage foo;
};
const KlassB = class {
  @localStorage foo;
}
const klassA = new KlassA();
const klassB = new KlassB();

klassA.foo = 'bar';
klassB.foo; // 'bar'

window.dispatchEvent(
  new StorageEvent('storage', { key: 'foo', newValue: 'baz', oldValue: 'bar' })
);
klassA.foo; // 'baz'
klassB.foo; // 'baz'
```

Due to limitations of the Web Storage API, direct changes to the storage 
bypassing the decorator can not be observed. Therefore you _should not_
manipulate `window.localStorage` or `window.sessionStorage` directly.

## Testing

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
  window.localStorage.setItem('foo', 'bar');
  initializeLocalStorageKey('foo');
});

test('some code relying on a value in session storage', function() {
  window.sessionStorage.setItem('foo', 'bar');
  initializeSessionStorageKey('foo');
});
```

Contributing
------------------------------------------------------------------------------

See the [Contributing](CONTRIBUTING.md) guide for details.


License
------------------------------------------------------------------------------

This project is licensed under the [MIT License](LICENSE.md).
