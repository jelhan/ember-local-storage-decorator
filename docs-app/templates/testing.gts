import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import NavBar from '../components/nav-bar.gts';

<template>
  {{pageTitle "Testing Guide"}}

  <NavBar />

  <div class="container">
    <section class="doc-section">
      <h2>Testing Guide</h2>
      <p>
        Browser storage is global state that persists between test runs. To
        avoid leaking state between tests and ensure reliable test results, you
        need to properly clean up storage and clear internal caches.
      </p>

      <div class="warning">
        <strong>Important:</strong>
        Always clear both the browser storage AND the internal caches before
        each test to ensure a clean slate and avoid test pollution.
      </div>

      <h3>Testing with TrackedStorage or Pre-instantiated Instances</h3>

      <h4>Basic Setup</h4>
      <pre>import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { trackedLocalStorage } from 'ember-local-storage-decorator';

module('Integration | Component | my-component', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    // Clear the storage
    window.localStorage.clear();

    // Clear the internal cache
    trackedLocalStorage.clearCache();
  });
});</pre>

      <h4>Testing Custom TrackedStorage Instances</h4>
      <p>
        If you're creating your own
        <code>TrackedStorage</code>
        instances in your components or services, you have two options:
      </p>

      <pre>import { TrackedStorage } from 'ember-local-storage-decorator';

// Option 1: Call clearCache() on each instance
module('Integration | Component | my-component', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    window.localStorage.clear();
    this.storage = new TrackedStorage(window.localStorage, 'test');
  });

  test('it works', function (assert) {
    this.storage.setItem('key', 'value');
    assert.strictEqual(this.storage.getItem('key'), 'value');
  });
});

// Option 2: Create new instances for each test
module('Integration | Component | my-component', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    window.localStorage.clear();
  });

  test('it works', function (assert) {
    const storage = new TrackedStorage(window.localStorage, 'test');
    storage.setItem('key', 'value');
    assert.strictEqual(storage.getItem('key'), 'value');
  });
});</pre>

      <h3>Testing with Decorators</h3>

      <h4>Basic Setup</h4>
      <p>
        For decorator-based code, use the provided helper functions to clear the
        caches:
      </p>

      <pre>import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  clearLocalStorageCache,
  clearSessionStorageCache
} from 'ember-local-storage-decorator';

module('Integration | Component | my-component', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    // Clear the storage
    window.localStorage.clear();
    window.sessionStorage.clear();

    // Clear the internal caches
    clearLocalStorageCache();
    clearSessionStorageCache();
  });
});</pre>

      <h4>Reinitializing Keys</h4>
      <p>
        Decorators perform initialization when a property is first decorated. If
        you need to manually set a storage value in tests after the decorator
        has been applied, you must reinitialize the key:
      </p>

      <pre>import {
  initializeLocalStorageKey,
  initializeSessionStorageKey,
  DEFAULT_PREFIX
} from 'ember-local-storage-decorator';

test('some code relying on a value in local storage', function (assert) {
  // Manually set a value in storage
  window.localStorage.setItem(
    `${DEFAULT_PREFIX}:foo`,
    JSON.stringify('bar')
  );

  // Reinitialize the key so the decorator picks up the change
  initializeLocalStorageKey('foo');

  // Now your component will see the new value
  // ...
});

test('some code relying on a value in session storage', function (assert) {
  // Manually set a value in storage
  window.sessionStorage.setItem(
    `${DEFAULT_PREFIX}:foo`,
    JSON.stringify('bar')
  );

  // Reinitialize the key
  initializeSessionStorageKey('foo');

  // Now your component will see the new value
  // ...
});</pre>

      <div class="note">
        <strong>Remember:</strong>
        When manually setting values in storage for testing, you must:
        <ul>
          <li>Use the prefixed key format (<code
            >__tracked_storage__:keyName</code>)</li>
          <li>JSON-stringify the value</li>
          <li>Call the appropriate initialization function</li>
        </ul>
      </div>

      <h3>Complete Test Examples</h3>

      <h4>Testing a Component with TrackedStorage</h4>
      <pre>import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import { trackedLocalStorage } from 'ember-local-storage-decorator';
import { hbs } from 'ember-cli-htmlbars';

module('Integration | Component | user-profile', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    window.localStorage.clear();
    trackedLocalStorage.clearCache();
  });

  test('it renders user data from storage', async function (assert) {
    trackedLocalStorage.setItem('user', {
      name: 'Alice',
      email: 'alice@example.com'
    });

    await render(hbs`&lt;UserProfile /&gt;`);

    assert.dom('[data-test-user-name]').hasText('Alice');
    assert.dom('[data-test-user-email]').hasText('alice@example.com');
  });

  test('it saves user data to storage', async function (assert) {
    await render(hbs`&lt;UserProfile /&gt;`);

    await fillIn('[data-test-name-input]', 'Bob');
    await fillIn('[data-test-email-input]', 'bob@example.com');
    await click('[data-test-save-button]');

    const savedUser = trackedLocalStorage.getItem('user');
    assert.deepEqual(savedUser, {
      name: 'Bob',
      email: 'bob@example.com'
    });
  });
});</pre>

      <h4>Testing a Component with Decorators</h4>
      <pre>import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click } from '@ember/test-helpers';
import {
  clearLocalStorageCache,
  initializeLocalStorageKey,
  DEFAULT_PREFIX
} from 'ember-local-storage-decorator';
import { hbs } from 'ember-cli-htmlbars';

module('Integration | Component | theme-switcher', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    window.localStorage.clear();
    clearLocalStorageCache();
  });

  test('it uses default theme when no value is stored', async function (assert) {
    await render(hbs`&lt;ThemeSwitcher /&gt;`);

    assert.dom('[data-test-theme]').hasText('light');
  });

  test('it loads theme from storage', async function (assert) {
    // Set initial value in storage
    window.localStorage.setItem(`${DEFAULT_PREFIX}:theme`, JSON.stringify('dark'));
    initializeLocalStorageKey('theme');

    await render(hbs`&lt;ThemeSwitcher /&gt;`);

    assert.dom('[data-test-theme]').hasText('dark');
  });

  test('it toggles and saves theme', async function (assert) {
    await render(hbs`&lt;ThemeSwitcher /&gt;`);

    assert.dom('[data-test-theme]').hasText('light');

    await click('[data-test-toggle-button]');

    assert.dom('[data-test-theme]').hasText('dark');

    // Verify it was saved to storage
    const storedTheme = window.localStorage.getItem(`${DEFAULT_PREFIX}:theme`);
    assert.strictEqual(JSON.parse(storedTheme), 'dark');
  });
});</pre>

      <h3>Testing Services</h3>
      <pre>import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';
import { trackedLocalStorage } from 'ember-local-storage-decorator';

module('Unit | Service | user-preferences', function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    window.localStorage.clear();
    trackedLocalStorage.clearCache();
  });

  test('it provides default preferences', function (assert) {
    const service = this.owner.lookup('service:user-preferences');

    assert.strictEqual(service.theme, 'light');
    assert.strictEqual(service.language, 'en');
  });

  test('it persists preference changes', function (assert) {
    const service = this.owner.lookup('service:user-preferences');

    service.theme = 'dark';

    assert.strictEqual(
      trackedLocalStorage.getItem('theme'),
      'dark'
    );
  });

  test('it resets all preferences', function (assert) {
    const service = this.owner.lookup('service:user-preferences');

    service.theme = 'dark';
    service.language = 'fr';
    service.reset();

    assert.strictEqual(trackedLocalStorage.getItem('theme'), null);
    assert.strictEqual(trackedLocalStorage.getItem('language'), null);
  });
});</pre>

      <h3>Testing Best Practices</h3>
      <div class="features-grid">
        <div class="feature-card">
          <div class="feature-icon">🧹</div>
          <h3>Clean State</h3>
          <p>Always clear storage and caches in beforeEach hooks</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🔍</div>
          <h3>Verify Storage</h3>
          <p>Assert that values are correctly saved to storage</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🎯</div>
          <h3>Test Isolation</h3>
          <p>Use unique prefixes for different test scenarios</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">📋</div>
          <h3>Test Defaults</h3>
          <p>Verify default values work when storage is empty</p>
        </div>
      </div>

      <h3>Helper Functions Reference</h3>
      <table class="api-table">
        <thead>
          <tr>
            <th>Function</th>
            <th>Description</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><code>clearLocalStorageCache()</code></td>
            <td>Clears the internal cache for localStorage decorators</td>
          </tr>
          <tr>
            <td><code>clearSessionStorageCache()</code></td>
            <td>Clears the internal cache for sessionStorage decorators</td>
          </tr>
          <tr>
            <td><code>initializeLocalStorageKey(key)</code></td>
            <td>Reinitializes a specific localStorage key</td>
          </tr>
          <tr>
            <td><code>initializeSessionStorageKey(key)</code></td>
            <td>Reinitializes a specific sessionStorage key</td>
          </tr>
          <tr>
            <td><code>DEFAULT_PREFIX</code></td>
            <td>Constant containing the default prefix value</td>
          </tr>
        </tbody>
      </table>

      <div class="hero-buttons cta-buttons">
        <LinkTo @route="index" class="btn btn-primary">
          Back to Home
        </LinkTo>
        <LinkTo @route="decorators" class="btn btn-secondary">
          ← Back to Decorators
        </LinkTo>
      </div>
    </section>
  </div>
</template>
