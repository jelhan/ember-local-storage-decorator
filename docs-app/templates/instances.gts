import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import { shiki } from '../modifiers/shiki.ts';

<template>
  {{pageTitle "Pre-instantiated Instances"}}

  <div class="container">
    <section class="doc-section">
      <h2>Pre-instantiated Storage Instances</h2>
      <p>
        For convenience, the library exports pre-instantiated
        <code>TrackedStorage</code>
        instances that are ready to use immediately. These instances use the
        default prefix and are perfect for quick usage without needing to create
        your own instances.
      </p>

      <h3>Available Instances</h3>
      <ul>
        <li><code>trackedLocalStorage</code>
          - Uses
          <code>window.localStorage</code></li>
        <li><code>trackedSessionStorage</code>
          - Uses
          <code>window.sessionStorage</code></li>
      </ul>

      <h3>Basic Usage</h3>
      <pre
        {{shiki}}
      >import { trackedLocalStorage, trackedSessionStorage } from 'ember-local-storage-decorator';
import Component from '@glimmer/component';

export default class MyComponent extends Component {
  get user() {
    return trackedLocalStorage.getItem('user');
  }

  updateUser = (user) => {
    trackedLocalStorage.setItem('user', user);
  }

  get tempData() {
    return trackedSessionStorage.getItem('tempData');
  }

  updateTempData = (data) => {
    trackedSessionStorage.setItem('tempData', data);
  }
}</pre>

      <h3>Why Use Pre-instantiated Instances?</h3>
      <div class="features-grid">
        <div class="feature-card">
          <div class="feature-icon">⚡</div>
          <h3>Quick Setup</h3>
          <p>No need to create instances - just import and use</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🔄</div>
          <h3>Shared State</h3>
          <p>Same instance across your entire app ensures consistency</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🎯</div>
          <h3>Simple API</h3>
          <p>Perfect for straightforward use cases</p>
        </div>
      </div>

      <h3>Complete Example</h3>
      <pre {{shiki}}>import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { trackedLocalStorage } from 'ember-local-storage-decorator';

export default class UserProfile extends Component {
  @tracked isEditing = false;

  get userData() {
    return trackedLocalStorage.getItem('currentUser') || {
      name: '',
      email: '',
      preferences: {}
    };
  }

  saveProfile = (formData) => {
    trackedLocalStorage.setItem('currentUser', {
      ...this.userData,
      ...formData,
      lastModified: new Date().toISOString()
    });
  };

  clearProfile = () => {
    trackedLocalStorage.removeItem('currentUser');
  };

  get hasProfile() {
    return trackedLocalStorage.getItem('currentUser') !== null;
  }
}</pre>

      <h3>Working with Session Storage</h3>
      <p>
        Use
        <code>trackedSessionStorage</code>
        for data that should only persist for the current browser session (data
        is cleared when the tab is closed).
      </p>

      <pre
        {{shiki}}
      >import { trackedSessionStorage } from 'ember-local-storage-decorator';

export default class ShoppingCart extends Component {
  get cartItems() {
    return trackedSessionStorage.getItem('cart') || [];
  }

  addToCart = (item) => {
    const cart = this.cartItems;
    trackedSessionStorage.setItem('cart', [...cart, item]);
  };

  clearCart = () => {
    trackedSessionStorage.removeItem('cart');
  };

  get cartTotal() {
    return this.cartItems.reduce((sum, item) => sum + item.price, 0);
  }
}</pre>

      <h3>Full API Reference</h3>
      <p>
        The pre-instantiated instances expose the same API as the
        <code>TrackedStorage</code>
        class:
      </p>

      <table class="docs-table">
        <thead>
          <tr>
            <th>Method</th>
            <th>Description</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><code>getItem(key)</code></td>
            <td>Retrieve a value from storage</td>
          </tr>
          <tr>
            <td><code>setItem(key, value)</code></td>
            <td>Store a value (JSON serialized automatically)</td>
          </tr>
          <tr>
            <td><code>removeItem(key)</code></td>
            <td>Remove a value from storage</td>
          </tr>
          <tr>
            <td><code>clear()</code></td>
            <td>Clear all items with the default prefix</td>
          </tr>
          <tr>
            <td><code>key(index)</code></td>
            <td>Get key at the specified index</td>
          </tr>
          <tr>
            <td><code>length</code></td>
            <td>Number of stored items (getter property)</td>
          </tr>
          <tr>
            <td><code>clearCache()</code></td>
            <td>Clear internal cache (useful for testing)</td>
          </tr>
        </tbody>
      </table>

      <h3>Advanced Patterns</h3>

      <h4>Service-based Storage</h4>
      <p>Encapsulate storage logic in a service for reusability:</p>
      <pre {{shiki}}>import Service from '@ember/service';
import { trackedLocalStorage } from 'ember-local-storage-decorator';

export default class UserPreferencesService extends Service {
  get theme() {
    return trackedLocalStorage.getItem('theme') || 'light';
  }

  set theme(value) {
    trackedLocalStorage.setItem('theme', value);
  }

  get language() {
    return trackedLocalStorage.getItem('language') || 'en';
  }

  set language(value) {
    trackedLocalStorage.setItem('language', value);
  }

  reset() {
    trackedLocalStorage.removeItem('theme');
    trackedLocalStorage.removeItem('language');
  }
}</pre>

      <h4>Computed Properties</h4>
      <pre {{shiki}}>import Component from '@glimmer/component';
import { trackedLocalStorage } from 'ember-local-storage-decorator';

export default class Dashboard extends Component {
  get settings() {
    return trackedLocalStorage.getItem('dashboardSettings') || {
      layout: 'grid',
      itemsPerPage: 20,
      sortBy: 'date'
    };
  }

  get isGridLayout() {
    return this.settings.layout === 'grid';
  }

  get isListLayout() {
    return this.settings.layout === 'list';
  }

  toggleLayout = () => {
    const newLayout = this.isGridLayout ? 'list' : 'grid';
    trackedLocalStorage.setItem('dashboardSettings', {
      ...this.settings,
      layout: newLayout
    });
  };
}</pre>

      <div class="note">
        <strong>Cross-Tab Synchronization:</strong>
        Changes made using the pre-instantiated instances are automatically
        synchronized across different browser tabs, just like with custom
        <code>TrackedStorage</code>
        instances.
      </div>

      <div class="note">
        <strong>Shared Prefix:</strong>
        Both
        <code>trackedLocalStorage</code>
        and
        <code>trackedSessionStorage</code>
        use the default prefix (<code>__tracked_storage__</code>). If you need a
        custom prefix, create your own
        <code>TrackedStorage</code>
        instance instead.
      </div>

      <div class="hero-buttons cta-buttons">
        <LinkTo @route="decorators" class="btn btn-primary">
          Next: Property Decorators →
        </LinkTo>
        <LinkTo @route="tracked-storage" class="btn btn-secondary">
          ← Back to TrackedStorage
        </LinkTo>
      </div>
    </section>
  </div>
</template>
