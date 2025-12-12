import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import { shiki } from '../modifiers/shiki';

<template>
  {{pageTitle "Decorators - Ember Tracked Storage"}}

  <div class="container">
    <section class="doc-section">
      <h2>Property Decorators</h2>
      <p>
        For a more traditional Ember approach, use the
        <code>@localStorage</code>
        and
        <code>@sessionStorage</code>
        decorators to bind class properties directly to browser storage. This
        provides a clean, declarative API that feels natural in Ember
        applications.
      </p>

      <h3>Basic Usage</h3>
      <pre
        {{shiki}}
      >import { localStorage, sessionStorage } from 'ember-local-storage-decorator';
import Component from '@glimmer/component';

export default class MyComponent extends Component {
  @localStorage user;
  @sessionStorage tempData;
}</pre>

      <p>
        The decorators attach a getter to read the value from storage and a
        setter to write changes to storage. Changes are automatically reactive
        and persist across page reloads.
      </p>

      <h3>Simple Example</h3>
      <pre {{shiki}}>const Klass = class {
  @localStorage user;
  @sessionStorage tempData;
}
const klass = new Klass();

klass.user = 'Jane';
klass.user; // 'Jane'

klass.tempData = { chatRoomId: 42 };
klass.tempData; // { chatRoomId: 42 }</pre>

      <h3>Custom Storage Keys</h3>
      <p>
        You can specify a different key to be used in storage by passing it as
        an argument to the decorator:
      </p>
      <pre {{shiki}}>const Klass = class {
  @localStorage('user') currentUser;
  @sessionStorage('tempData') sessionInfo;
};
const klass = new Klass();

klass.currentUser = 'Jane'; // stored under key 'user'
klass.currentUser; // 'Jane'

// In actual storage:
window.localStorage.getItem('__tracked_storage__:user'); // '"Jane"'

klass.sessionInfo = { chatRoomId: 42 };
klass.sessionInfo; // { chatRoomId: 42 }

// In actual storage:
window.sessionStorage.getItem('__tracked_storage__:tempData'); // '{"chatRoomId":42}'</pre>

      <h3>Default Values</h3>
      <p>
        You can provide a default value that will be used if no value exists in
        storage:
      </p>
      <pre {{shiki}}>const Klass = class {
  @localStorage foo = 'defaultValue';
  @sessionStorage bar = { count: 0 };
};

const klass = new Klass();
klass.foo; // 'defaultValue' (if not set in storage)
klass.bar; // { count: 0 } (if not set in storage)</pre>

      <h3>Real-World Examples</h3>

      <h4>User Preferences Component</h4>
      <pre {{shiki}}>import Component from '@glimmer/component';
import { localStorage } from 'ember-local-storage-decorator';

export default class UserPreferences extends Component {
  @localStorage theme = 'light';
  @localStorage language = 'en';
  @localStorage notifications = true;

  toggleTheme = () => {
    this.theme = this.theme === 'light' ? 'dark' : 'light';
  };

  updateLanguage = (lang) => {
    this.language = lang;
  };

  toggleNotifications = () => {
    this.notifications = !this.notifications;
  };
}</pre>

      <h4>Form Draft Auto-Save</h4>
      <pre {{shiki}}>import Component from '@glimmer/component';
import { sessionStorage } from 'ember-local-storage-decorator';

export default class DraftForm extends Component {
  @sessionStorage('formDraft') draft = {
    title: '',
    content: '',
    tags: []
  };

  updateField = (field, value) => {
    this.draft = {
      ...this.draft,
      [field]: value
    };
  };

  clearDraft = () => {
    this.draft = {
      title: '',
      content: '',
      tags: []
    };
  };
}</pre>

      <h4>Shopping Cart</h4>
      <pre {{shiki}}>import Component from '@glimmer/component';
import { localStorage } from 'ember-local-storage-decorator';

export default class ShoppingCart extends Component {
  @localStorage('cart') items = [];

  get total() {
    return this.items.reduce((sum, item) => {
      return sum + (item.price * item.quantity);
    }, 0);
  }

  addItem = (product, quantity = 1) => {
    const existingItem = this.items.find(i => i.id === product.id);

    if (existingItem) {
      this.items = this.items.map(item =>
        item.id === product.id
          ? { ...item, quantity: item.quantity + quantity }
          : item
      );
    } else {
      this.items = [...this.items, { ...product, quantity }];
    }
  };

  removeItem = (productId) => {
    this.items = this.items.filter(item => item.id !== productId);
  };

  clearCart = () => {
    this.items = [];
  };
}</pre>

      <h3>Decorator vs Direct Access</h3>
      <p>When should you use decorators vs.
        <code>TrackedStorage</code>
        or pre-instantiated instances?</p>

      <table class="docs-table">
        <thead>
          <tr>
            <th>Use Case</th>
            <th>Recommended Approach</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Simple property binding</td>
            <td><code>@localStorage</code> / <code>@sessionStorage</code></td>
          </tr>
          <tr>
            <td>Traditional Ember style</td>
            <td><code>@localStorage</code> / <code>@sessionStorage</code></td>
          </tr>
          <tr>
            <td>Complex storage operations</td>
            <td><code>TrackedStorage</code> class</td>
          </tr>
          <tr>
            <td>Custom prefix needed</td>
            <td><code>TrackedStorage</code> class</td>
          </tr>
          <tr>
            <td>Quick one-off usage</td>
            <td><code>trackedLocalStorage</code>
              /
              <code>trackedSessionStorage</code></td>
          </tr>
        </tbody>
      </table>

      <h3>Important Considerations</h3>

      <div class="note">
        <strong>Immutability:</strong>
        Values retrieved using decorators are deep frozen, just like with
        <code>TrackedStorage</code>. To update a value, you must assign a new
        object rather than mutating the existing one.
      </div>

      <pre {{shiki}}>@localStorage user = { name: 'Alice' };

// This will NOT work:
// this.user.name = 'Bob'; // Error in strict mode!

// Instead, create a new object:
this.user = { ...this.user, name: 'Bob' };</pre>

      <div class="note">
        <strong>Cross-Instance Reactivity:</strong>
        Decorators use
        <code>TrackedStorage</code>
        internally, so changes are automatically synchronized across different
        component instances and browser tabs.
      </div>

      <div class="warning">
        <strong>Warning:</strong>
        Do not manipulate
        <code>window.localStorage</code>
        or
        <code>window.sessionStorage</code>
        directly when using decorators. Always use the decorated properties to
        ensure reactivity works correctly.
      </div>

      <h3>TypeScript Support</h3>
      <p>The decorators work seamlessly with TypeScript:</p>
      <pre
        {{shiki}}
      >import { localStorage, sessionStorage } from 'ember-local-storage-decorator';

interface User {
  id: number;
  name: string;
  email: string;
}

export default class MyComponent extends Component {
  @localStorage user: User | null = null;
  @sessionStorage preferences: Record&lt;string, unknown&gt; = {};
}</pre>

      <div class="hero-buttons cta-buttons">
        <LinkTo @route="testing" class="btn btn-primary">
          Next: Testing Guide →
        </LinkTo>
        <LinkTo @route="instances" class="btn btn-secondary">
          ← Back to Pre-instantiated Instances
        </LinkTo>
      </div>
    </section>
  </div>
</template>
