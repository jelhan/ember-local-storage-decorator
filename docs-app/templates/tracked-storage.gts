import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import { shiki } from '../modifiers/shiki';

<template>
  {{pageTitle "TrackedStorage"}}

  <div class="container">
    <section class="doc-section">
      <h2>TrackedStorage Class</h2>
      <p>
        The
        <code>TrackedStorage</code>
        class is the most flexible option - a tracked wrapper around the Web
        Storage API that works with both
        <code>localStorage</code>
        and
        <code>sessionStorage</code>. All operations are reactive and will
        trigger Ember's reactivity system.
      </p>

      <h3>Basic Usage</h3>
      <pre
        {{shiki}}
      >import { TrackedStorage } from 'ember-local-storage-decorator';
import Component from '@glimmer/component';

export default class MyComponent extends Component {
  storage = new TrackedStorage(window.localStorage);

  get user() {
    return this.storage.getItem('user');
  }

  updateUser = (name) => {
    this.storage.setItem('user', { name });
  }
}</pre>

      <h3>Constructor Options</h3>
      <p>The <code>TrackedStorage</code> constructor accepts two parameters:</p>
      <pre {{shiki}}>new TrackedStorage(storageArea, prefix?)</pre>

      <table class="docs-table">
        <thead>
          <tr>
            <th>Parameter</th>
            <th>Type</th>
            <th>Description</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><code>storageArea</code></td>
            <td><code>Storage</code></td>
            <td>Either
              <code>window.localStorage</code>
              or
              <code>window.sessionStorage</code></td>
          </tr>
          <tr>
            <td><code>prefix</code></td>
            <td><code>string</code></td>
            <td>Optional namespace prefix (default:
              <code>__tracked_storage__</code>)</td>
          </tr>
        </tbody>
      </table>

      <h3>Examples</h3>

      <pre {{shiki}}>// Using localStorage with default prefix
const storage = new TrackedStorage(window.localStorage);

// Using sessionStorage with default prefix
const storage = new TrackedStorage(window.sessionStorage);

// Using localStorage with custom prefix
const storage = new TrackedStorage(window.localStorage, 'my_app');</pre>

      <h3>API Reference</h3>
      <table class="docs-table">
        <thead>
          <tr>
            <th>Method</th>
            <th>Description</th>
            <th>Returns</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><code>getItem(key)</code></td>
            <td>Retrieve a value from storage</td>
            <td><code>unknown</code></td>
          </tr>
          <tr>
            <td><code>setItem(key, value)</code></td>
            <td>Store a value (JSON serialized automatically)</td>
            <td><code>void</code></td>
          </tr>
          <tr>
            <td><code>removeItem(key)</code></td>
            <td>Remove a value from storage</td>
            <td><code>void</code></td>
          </tr>
          <tr>
            <td><code>clear()</code></td>
            <td>Clear all items with the same prefix</td>
            <td><code>void</code></td>
          </tr>
          <tr>
            <td><code>key(index)</code></td>
            <td>Get key at the specified index</td>
            <td><code>string | null</code></td>
          </tr>
          <tr>
            <td><code>length</code></td>
            <td>Number of stored items (getter property)</td>
            <td><code>number</code></td>
          </tr>
          <tr>
            <td><code>clearCache()</code></td>
            <td>Clear internal cache (useful for testing)</td>
            <td><code>void</code></td>
          </tr>
        </tbody>
      </table>

      <h3>Detailed Examples</h3>

      <h4>Storing and Retrieving Data</h4>
      <pre {{shiki}}>const storage = new TrackedStorage(window.localStorage);

// Store primitive values
storage.setItem('count', 42);
storage.setItem('name', 'Alice');
storage.setItem('active', true);

// Store objects and arrays
storage.setItem('user', {
  id: 1,
  name: 'Alice',
  email: 'alice@example.com'
});

storage.setItem('tags', ['ember', 'javascript', 'web']);

// Retrieve values
const count = storage.getItem('count'); // 42
const user = storage.getItem('user'); // { id: 1, name: 'Alice', ... }
const tags = storage.getItem('tags'); // ['ember', 'javascript', 'web']</pre>

      <h4>Removing and Clearing Data</h4>
      <pre {{shiki}}>// Remove a specific item
storage.removeItem('count');

// Clear all items with the same prefix
storage.clear();</pre>

      <h4>Iterating Over Keys</h4>
      <pre {{shiki}}>const storage = new TrackedStorage(window.localStorage);

// Get number of items
console.log(storage.length); // e.g., 3

// Iterate through keys
for (let i = 0; i &lt; storage.length; i++) {
  const key = storage.key(i);
  const value = storage.getItem(key);
  console.log(key, value);
}</pre>

      <h3>Important Behaviors</h3>

      <div class="note">
        <strong>JSON Serialization:</strong>
        Values are automatically serialized to JSON when stored and deserialized
        when retrieved. Only values that can be serialized to JSON are supported
        (primitives, objects, arrays, etc.). Functions, symbols, and undefined
        values cannot be stored.
      </div>

      <div class="note">
        <strong>Deep Freezing:</strong>
        Retrieved objects and arrays are deep frozen using
        <code>Object.freeze()</code>
        to prevent accidental mutation. If you need to modify a value, you must
        create a new object and call
        <code>setItem()</code>
        again.
      </div>

      <pre {{shiki}}>const storage = new TrackedStorage(window.localStorage);
storage.setItem('data', { items: ['a', 'b'] });

const data = storage.getItem('data');
Object.isFrozen(data); // true
Object.isFrozen(data.items); // true

// This will throw an error in strict mode
// data.items.push('c'); // Error!

// Instead, create a new object
const newData = {
  items: [...data.items, 'c']
};
storage.setItem('data', newData);</pre>

      <h3>Cross-Instance Reactivity</h3>
      <p>
        Changes are automatically observed across different
        <code>TrackedStorage</code>
        instances that share the same storage area and prefix. The library also
        responds to
        <code>StorageEvent</code>s from other browser tabs.
      </p>

      <pre {{shiki}}>const instanceA = new TrackedStorage(window.localStorage);
const instanceB = new TrackedStorage(window.localStorage);

instanceA.setItem('foo', 'bar');
instanceB.getItem('foo'); // 'bar' - automatically synced!

// Changes from other tabs are also detected
// When another tab calls:
// otherTabStorage.setItem('foo', 'baz');
// This instance will automatically update</pre>

      <h3>Prefix Isolation</h3>
      <p>
        The prefix system ensures that
        <code>TrackedStorage</code>
        keys don't conflict with other code using the same storage. Different
        prefixes create isolated namespaces.
      </p>

      <pre
        {{shiki}}
      >const appStorage = new TrackedStorage(window.localStorage, 'my_app');
const adminStorage = new TrackedStorage(window.localStorage, 'admin');

appStorage.setItem('user', 'Alice');
adminStorage.setItem('user', 'Bob');

appStorage.getItem('user'); // 'Alice'
adminStorage.getItem('user'); // 'Bob'

// In the actual storage:
// 'my_app:user' => '"Alice"'
// 'admin:user' => '"Bob"'</pre>

      <div class="warning">
        <strong>Warning:</strong>
        Due to limitations of the Web Storage API, direct changes to
        <code>window.localStorage</code>
        or
        <code>window.sessionStorage</code>
        bypassing TrackedStorage cannot be observed. Always use the
        TrackedStorage methods to ensure reactivity.
      </div>

      <div class="hero-buttons cta-buttons">
        <LinkTo @route="instances" class="btn btn-primary">
          Next: Pre-instantiated Instances →
        </LinkTo>
        <LinkTo @route="index" class="btn btn-secondary">
          ← Back to Home
        </LinkTo>
      </div>
    </section>
  </div>
</template>
