Ember Local Storage Decorator
==============================================================================

Decorator to use `localStorage` in Ember Octane.


Compatibility
------------------------------------------------------------------------------

* Ember.js v3.28 or above
* Ember CLI v3.28 or above
* Node.js v14 or above


Installation
------------------------------------------------------------------------------

```
ember install ember-local-storage-decorator
```


Usage
------------------------------------------------------------------------------

```js
import localStorage from 'ember-local-storage-decorator';
import Component from '@glimmer/component';

export default class MyComponent extends Component {
  @localStorage foo
}
```

Decorate a class property with `@localStorage` to bind it to `localStorage`.
It will attach a getter to read the value from `localStorage` and a setter
to write changes to `localStorage`.

```js
const Klass = class {
  @localStorage foo;
}
const klass = new Klass();

klass.foo = 'baz';
window.localStorage.getItem('foo'); // '"baz"'
```

You may specify another key to be used in local storage as an argument to the
decorator.

```js
const Klass = class {
  @localStorage('bar') foo;
};
const klass = new Klass();

klass.foo = 'baz';
window.localStorage.getItem('bar'); // '"baz"'
```

The value is stored as a JSON string in `localStorage`. Therefore only values
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

Due to limitations of `localStorage` direct changes of the value bypassing
`@localStorage` decorator can not be observed. Therefore you _should not_
manipulate the `localStorage` directly.

## Testing

`window.localStorage` is a global state, which is shared between test runs.
The decorator uses a global cache, which is also shared between instances.
Both are not reset automatically between test jobs.

To avoid leaking state between test jobs it's recommended to clear the cache
of `@localStorage` decorator before each test. A `clearLocalStorageCache`
helper function is exported from `ember-local-storage-decorator` to do so.

Additionally `window.localStorage` should be either cleared before each test
run or mocked.

```js
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { clearLocalStorageCache } from 'ember-local-storage-decorator';

module('Integration | Component | my-component', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    clearLocalStorageCache();
    window.localStorage.clear();
  });
});
```

`@localStorage` decorator performs some initialization work when a property
is decorated. This includes picking up the current value from local storage
and adding it to its internal cache. Manual changes to local storage _after_
a property has been decorated are _not_ picked up. As class instances are
often shared between test jobs, you need to manual reinitialize a local
storage key in tests.

```js
import { initalizeLocalStorageKey } from 'ember-local-storage-decorator';

test('some code relying on a value in local storage', function() {
  window.localStorage.setItem('foo', 'bar');
  initalizeLocalStorageKey('foo');
});
```

Contributing
------------------------------------------------------------------------------

See the [Contributing](CONTRIBUTING.md) guide for details.


License
------------------------------------------------------------------------------

This project is licensed under the [MIT License](LICENSE.md).
