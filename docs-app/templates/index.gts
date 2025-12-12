import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import {
  TrackedStorage,
  trackedLocalStorage,
  localStorage,
} from '#src/index.ts';
import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import NavBar from '../components/nav-bar.gts';
import { shiki } from '../modifiers/shiki';

export default class Index extends Component {
  storage = new TrackedStorage(window.localStorage);

  @tracked demoName = '';
  @tracked demoEmail = '';
  @localStorage counter = 0;

  get storedUser() {
    return trackedLocalStorage.getItem('demo_user');
  }

  get storedCounter(): number | null {
    const value = this.storage.getItem('counter');
    return value !== null ? Number(value) : null;
  }

  updateName = (event: Event) => {
    this.demoName = (event.target as HTMLInputElement).value;
  };

  updateEmail = (event: Event) => {
    this.demoEmail = (event.target as HTMLInputElement).value;
  };

  get allStorageKeys() {
    const keys = [];
    for (let i = 0; i < this.storage.length; i++) {
      const key = this.storage.key(i);
      if (key) keys.push(key);
    }
    return keys;
  }

  saveUser = () => {
    if (this.demoName && this.demoEmail) {
      trackedLocalStorage.setItem('demo_user', {
        name: this.demoName,
        email: this.demoEmail,
        timestamp: new Date().toISOString(),
      });
    }
  };

  clearUser = () => {
    trackedLocalStorage.removeItem('demo_user');
    this.demoName = '';
    this.demoEmail = '';
  };

  increment = () => {
    this.counter = this.counter + 1;
  };

  decrement = () => {
    this.counter = this.counter - 1;
  };

  resetCounter = () => {
    this.counter = 0;
  };

  clearAll = () => {
    this.storage.clear();
  };

  <template>
    {{pageTitle "Home - Ember Local Storage Decorator"}}

    <NavBar />

    <div class="container">
      <section class="hero">
        <h1>Ember Local Storage Decorator</h1>
        <p>
          Reactive localStorage and sessionStorage for Ember with multiple APIs
          to fit your needs.
        </p>
        <div class="hero-buttons">
          <LinkTo @route="tracked-storage" class="btn btn-primary">
            Get Started
          </LinkTo>
          <a
            href="https://github.com/evoactivity/ember-local-storage-decorator"
            class="btn btn-secondary"
            target="_blank"
            rel="noopener noreferrer"
          >
            View on GitHub
          </a>
        </div>
      </section>

      <section class="demo-section">
        <h2>🎯 Interactive Demo</h2>
        <p>Try out the reactive storage features below. All changes are
          automatically persisted and will survive page refreshes!</p>

        <div class="demo-grid">
          <div class="demo-card">
            <h3>User Data Storage</h3>
            <p>Using <code>trackedLocalStorage</code></p>

            <div class="demo-controls">
              <label>
                Name
                <input
                  type="text"
                  placeholder="Enter name..."
                  value={{this.demoName}}
                  {{on "input" this.updateName}}
                  class="demo-input"
                />
              </label>
              <label>
                Email
                <input
                  type="email"
                  placeholder="Enter email..."
                  value={{this.demoEmail}}
                  {{on "input" this.updateEmail}}
                  class="demo-input"
                />
              </label>

              <div class="demo-actions">
                <button
                  type="button"
                  {{on "click" this.saveUser}}
                  class="btn btn-primary btn-small"
                >
                  Save User
                </button>
                <button
                  type="button"
                  {{on "click" this.clearUser}}
                  class="btn btn-secondary btn-small"
                >
                  Clear User
                </button>
              </div>
            </div>

            <pre class="demo-output">
              {{#if this.storedUser}}
                {{~(JSON.stringify this.storedUser null 2)~}}
              {{else}}
                {{~"No user data stored"~}}
              {{/if}}
            </pre>
          </div>

          <div class="demo-card">
            <h3>Reactive Counter</h3>
            <p>Using <code>@localStorage</code> class</p>

            <div class="demo-controls">
              <div class="counter-display">
                {{this.counter}}
              </div>

              <div class="demo-actions">
                <button
                  type="button"
                  {{on "click" this.increment}}
                  class="btn btn-primary btn-small"
                >
                  + Increment
                </button>
                <button
                  type="button"
                  {{on "click" this.decrement}}
                  class="btn btn-primary btn-small"
                >
                  - Decrement
                </button>
                <button
                  type="button"
                  {{on "click" this.resetCounter}}
                  class="btn btn-secondary btn-small"
                >
                  Reset
                </button>
              </div>
            </div>

            <pre class="demo-output">
              {{~"Stored value:"~}}&nbsp;{{~this.storedCounter~}}
            </pre>
          </div>

          <div class="demo-card">
            <h3>Storage Info</h3>
            <p>Inspect storage contents</p>

            <div class="demo-controls">
              <div>
                <strong>Storage Length:</strong>
                {{this.storage.length}}
              </div>
              <div>
                <strong>Keys:</strong>
                {{#if this.allStorageKeys.length}}
                  <ul class="storage-keys-list">
                    {{#each this.allStorageKeys as |key|}}
                      <li><code>{{key}}</code></li>
                    {{/each}}
                  </ul>
                {{else}}
                  <em>No keys stored</em>
                {{/if}}
              </div>

              <button
                type="button"
                {{on "click" this.clearAll}}
                class="btn btn-secondary btn-small"
              >
                Clear All Demo Storage
              </button>
            </div>
          </div>
        </div>

        <div class="note demo-note">
          <strong>💡 Try it:</strong>
          Open this page in multiple tabs or refresh the page - your data
          persists! The storage is fully reactive and updates automatically
          across all instances.
        </div>
      </section>

      <section class="doc-section">
        <h2>✨ Key Features</h2>
        <div class="features-grid">
          <div class="feature-card">
            <div class="feature-icon">⚡</div>
            <h3>Fully Reactive</h3>
            <p>Automatic UI updates when storage changes</p>
          </div>
          <div class="feature-card">
            <div class="feature-icon">🔄</div>
            <h3>Multiple APIs</h3>
            <p>Class-based, pre-instantiated, or decorators</p>
          </div>
          <div class="feature-card">
            <div class="feature-icon">🛡️</div>
            <h3>Type Safe</h3>
            <p>Full TypeScript support with type inference</p>
          </div>
          <div class="feature-card">
            <div class="feature-icon">🔒</div>
            <h3>Immutable</h3>
            <p>Deep-frozen objects prevent accidental mutation</p>
          </div>
          <div class="feature-card">
            <div class="feature-icon">🌐</div>
            <h3>Cross-Tab Sync</h3>
            <p>Updates propagate across browser tabs</p>
          </div>
          <div class="feature-card">
            <div class="feature-icon">🧪</div>
            <h3>Test Friendly</h3>
            <p>Easy cleanup and initialization utilities</p>
          </div>
        </div>
      </section>

      <section class="doc-section">
        <h2>🚀 Quick Start</h2>

        <h3>Installation</h3>
        <pre
          data-language="bash"
          {{shiki}}
        >pnpm install ember-local-storage-decorator
# or
yarn add ember-local-storage-decorator
# or
npm install ember-local-storage-decorator</pre>

        <h3>Choose Your API Style</h3>

        <p><strong>1. TrackedStorage Class</strong>
          - Most flexible, instance-based approach:</p>
        <pre
          {{shiki}}
        >import { TrackedStorage } from 'ember-local-storage-decorator';

storage = new TrackedStorage(window.localStorage);

storage.setItem('user', { name: 'Jane' });
storage.getItem('user'); // { name: 'Jane' }</pre>

        <p><strong>2. Pre-instantiated Instances</strong>
          - Ready-to-use convenience:</p>
        <pre
          {{shiki}}
        >import { trackedLocalStorage } from 'ember-local-storage-decorator';

trackedLocalStorage.setItem('user', { name: 'Jane' });
trackedLocalStorage.getItem('user'); // { name: 'Jane' }</pre>

        <p><strong>3. Property Decorators</strong>
          - Traditional Ember style:</p>
        <pre
          {{shiki}}
        >import { localStorage } from 'ember-local-storage-decorator';

class MyComponent extends Component {
  @localStorage user = { name: 'Jane' };
}</pre>

        <div class="hero-buttons cta-buttons">
          <LinkTo @route="tracked-storage" class="btn btn-primary">
            View Full Documentation
          </LinkTo>
        </div>
      </section>
    </div>
  </template>
}
