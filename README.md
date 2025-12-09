# Ember Local Storage Decorator


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

```js
import { TrackedStorage } from 'ember-local-storage-decorator';
import Component from '@glimmer/component';

export default class MyComponent extends Component {
  storage = new TrackedStorage(window.localStorage);
  // or: new TrackedStorage(window.sessionStorage)
  // or with custom prefix: new TrackedStorage(window.localStorage, 'my_app')

  get user() {
    return this.storage.getItem('user');
  }

  updateUser = (name) => {
    this.storage.setItem('user', { name });
  }
}
```

### TrackedStorage API

| Method | Description |
|--------|-------------|
| `getItem(key)` | Retrieve a value |
| `setItem(key, value)` | Store a value (JSON serialized automatically) |
| `removeItem(key)` | Remove a value |
| `clear()` | Clear all items with the same prefix |
| `key(index)` | Get key at index |
| `length` | Number of stored items |
| `clearCache()` | Clear internal cache (useful for testing) |

Values are automatically JSON serialized/deserialized and frozen to prevent mutation. TrackedStorage uses a prefix system (`__tracked_storage__` by default) to isolate its keys from other code using the same storage.

### 2. Pre-instantiated Storage Instances

For convenience, pre-instantiated TrackedStorage instances are provided:

```js
import { trackedLocalStorage, trackedSessionStorage } from 'ember-local-storage-decorator';
import Component from '@glimmer/component';

export default class MyComponent extends Component {
  get currentUser() {
    return trackedLocalStorage.getItem('user');
  }

  saveUser = (user) => {
    trackedLocalStorage.setItem('user', user);
  }
}
```

These instances use the default prefix and are ready to use immediately.

### 3. Property Decorators

For a more traditional approach, use the `@localStorage` and `@sessionStorage` decorators to bind class properties directly to storage:

```js
import { localStorage, sessionStorage } from 'ember-local-storage-decorator';
import Component from '@glimmer/component';

export default class MyComponent extends Component {
  @localStorage user;
  @sessionStorage tempData;
}
```

The decorators attach a getter to read the value from storage and a setter to write changes to storage.

### Basic Usage

```js
const Klass = class {
  @localStorage foo;
}
const klass = new Klass();

klass.foo = 'baz';
klass.foo; // 'baz'
```

### Custom Storage Key

You may specify a different key to be used in storage:

```js
const Klass = class {
  @localStorage('bar') foo;
};
const klass = new Klass();

klass.foo = 'baz'; // stored under key 'bar'
```

**sessionStorage Decorator:**

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

## ⭐ Common Features

All three approaches share these characteristics:

### JSON Serialization
Values are stored as JSON strings. Only values that can be serialized to JSON are supported.

### Deep Freezing
Objects and arrays are deep frozen to prevent accidental mutation:

```js
trackedLocalStorage.setItem('data', { items: ['a', 'b'] });
const data = trackedLocalStorage.getItem('data');

Object.isFrozen(data); // true
Object.isFrozen(data.items); // true
```

### Cross-Instance Reactivity
Changes are automatically observed across different class instances and respond to StorageEvents from other tabs:

```js
const instanceA = new TrackedStorage(window.localStorage);
const instanceB = new TrackedStorage(window.localStorage);

instanceA.setItem('foo', 'bar');
instanceB.getItem('foo'); // 'bar'

// Responds to changes from other browser tabs
window.dispatchEvent(
  new StorageEvent('storage', { 
    key: '__tracked_storage__:foo', 
    newValue: '"baz"' 
  })
);
instanceA.getItem('foo'); // 'baz'
```

### Prefix Isolation
TrackedStorage uses a prefix system (default: `__tracked_storage__`) to namespace its keys and avoid conflicts with other code using the same storage. The decorators use TrackedStorage internally, so they also benefit from this isolation.

## 🧪 Testing

Browser storage is global state that persists between test runs. To avoid leaking state between tests, you should clear both the storage and the internal caches.

### Testing with TrackedStorage or Pre-instantiated Instances

```js
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { trackedLocalStorage } from 'ember-local-storage-decorator';

module('Integration | Component | my-component', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    window.localStorage.clear();
    trackedLocalStorage.clearCache();
  });
});
```

If you're creating your own TrackedStorage instances, call `clearCache()` on each instance or simply create new instances in your tests.

### Testing with Decorators

For decorator-based code, use the provided helper functions:

```js
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { 
  clearLocalStorageCache, 
  clearSessionStorageCache,
  initializeLocalStorageKey,
  initializeSessionStorageKey
} from 'ember-local-storage-decorator';

module('Integration | Component | my-component', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    window.localStorage.clear();
    window.sessionStorage.clear();
    clearLocalStorageCache();
    clearSessionStorageCache();
  });
});
```

#### Reinitializing Keys

Decorators perform initialization when a property is first decorated. If you need to manually set a storage value in tests after the decorator has been applied, you must reinitialize the key:

```js
import { initializeLocalStorageKey, initializeSessionStorageKey } from 'ember-local-storage-decorator';

test('some code relying on a value in local storage', function() {
  // Manually set a value in storage
  window.localStorage.setItem('__tracked_storage__:foo', JSON.stringify('bar'));
  
  // Reinitialize the key so the decorator picks up the change
  initializeLocalStorageKey('foo');
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
