import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import {
  TrackedStorage,
  trackedLocalStorage,
  localStorage,
} from '#src/index.ts';
import { pageTitle } from 'ember-page-title';
import { shiki } from '../modifiers/shiki';
import { flashOnUpdate } from '../modifiers/flash-on-update';

export default class Index extends Component {
  storage = new TrackedStorage(window.localStorage);

  @tracked selectedPackageManager: 'pnpm' | 'yarn' | 'npm' = 'pnpm';

  @localStorage counter = 0;

  setPackageManager = (manager: 'pnpm' | 'yarn' | 'npm') => {
    this.selectedPackageManager = manager;
  };

  get isPnpm() {
    return this.selectedPackageManager === 'pnpm';
  }

  get isYarn() {
    return this.selectedPackageManager === 'yarn';
  }

  get isNpm() {
    return this.selectedPackageManager === 'npm';
  }

  get storedItems() {
    const items: Record<string, string> = {};
    for (let i = 0; i < trackedLocalStorage.length; i++) {
      const key = trackedLocalStorage.key(i);
      if (key) {
        const value = trackedLocalStorage.getItem(key);
        if (typeof value === 'string') {
          items[key] = value;
        }
      }
    }
    return items;
  }

  get hasStoredItems() {
    return Object.keys(this.storedItems).length > 0;
  }

  get storedCounter(): number | null {
    const value = this.storage.getItem('counter');
    return value !== null ? Number(value) : null;
  }

  get allStorageKeys() {
    const keys = [];
    for (let i = 0; i < this.storage.length; i++) {
      const key = this.storage.key(i);
      if (key) keys.push(key);
    }
    return keys;
  }

  get allStorageItems() {
    const items: Array<{ key: string; value: string }> = [];
    for (let i = 0; i < this.storage.length; i++) {
      const key = this.storage.key(i);
      if (key) {
        const value = this.storage.getItem(key);
        items.push({
          key,
          value: typeof value === 'string' ? value : JSON.stringify(value),
        });
      }
    }
    return items;
  }

  parseJSONLike = (input: string): string => {
    const trimmed = input.trim();

    // Check if it looks like an object or array
    if (
      (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
      (trimmed.startsWith('[') && trimmed.endsWith(']'))
    ) {
      try {
        // Try standard JSON first
        const parsed = JSON.parse(trimmed) as unknown;
        return JSON.stringify(parsed);
      } catch {
        try {
          // Try to fix unquoted keys by wrapping keys in quotes
          const fixed = trimmed
            // Add quotes around unquoted keys
            .replace(/([{,]\s*)([a-zA-Z_$][a-zA-Z0-9_$]*)\s*:/g, '$1"$2":')
            // Fix single quotes to double quotes
            .replace(/'/g, '"');
          const parsed = JSON.parse(fixed) as unknown;
          return JSON.stringify(parsed);
        } catch {
          // If still fails, return original
          return input;
        }
      }
    }

    return input;
  };

  addItem = (event: SubmitEvent) => {
    event.preventDefault();
    const form = event.target as HTMLFormElement;
    const formData = new FormData(form);
    const key = formData.get('key') as string;
    const value = formData.get('value') as string;

    if (key && value) {
      const valueToStore = this.parseJSONLike(value);
      trackedLocalStorage.setItem(key, valueToStore);
      form.reset();
    }
  };

  removeItem = (key: string) => {
    trackedLocalStorage.removeItem(key);
  };

  clearAllItems = () => {
    const keys = Object.keys(this.storedItems);
    keys.forEach((key) => trackedLocalStorage.removeItem(key));
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

  removeStorageItem = (key: string) => {
    this.storage.removeItem(key);
  };

  clearAll = () => {
    this.storage.clear();
  };

  <template>
    {{pageTitle "Home"}}

    <section class="hero">
      <h1>Ember Tracked Storage</h1>
      <p>
        Reactive localStorage and sessionStorage for Ember with multiple APIs to
        fit your needs.
      </p>
    </section>

    <div class="container">
      <section class="doc-section">
        <h2>🚀 Quick Start</h2>

        <h3>Installation</h3>

        <div class="install-tabs">
          <div class="tabs">
            <button
              type="button"
              class="tab {{if this.isPnpm 'active'}}"
              {{on "click" (fn this.setPackageManager "pnpm")}}
            >
              pnpm
            </button>
            <button
              type="button"
              class="tab {{if this.isYarn 'active'}}"
              {{on "click" (fn this.setPackageManager "yarn")}}
            >
              yarn
            </button>
            <button
              type="button"
              class="tab {{if this.isNpm 'active'}}"
              {{on "click" (fn this.setPackageManager "npm")}}
            >
              npm
            </button>
          </div>

          <div class="tab-content">
            {{#if this.isPnpm}}
              <pre
                data-language="bash"
                {{shiki}}
              >pnpm install ember-local-storage-decorator</pre>
            {{else if this.isYarn}}
              <pre
                data-language="bash"
                {{shiki}}
              >yarn add ember-local-storage-decorator</pre>
            {{else if this.isNpm}}
              <pre
                data-language="bash"
                {{shiki}}
              >npm install ember-local-storage-decorator</pre>
            {{/if}}
          </div>
        </div>

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

      </section>

      <h2>🎯 Interactive Demo</h2>
      <p>Try out the reactive storage features below. All changes are
        automatically persisted and will survive page refreshes! Try opening
        multiple tabs to see the cross tab syncing in action.</p>

      <div class="demo-grid">
        <div class="demo-card">
          <h3>Key-Value Storage</h3>

          <form class="demo-controls" {{on "submit" this.addItem}}>
            <label>
              Key
              <input
                type="text"
                name="key"
                placeholder="Enter key..."
                class="demo-input"
                required
              />
            </label>
            <label>
              Value
              <input
                type="text"
                name="value"
                placeholder="Enter value..."
                class="demo-input"
                required
              />
            </label>

            <div class="demo-actions">
              <button type="submit" class="btn btn-primary btn-small">
                Add Item
              </button>
            </div>
          </form>
        </div>

        <div class="demo-card">
          <h3>Reactive Counter</h3>

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
        </div>
      </div>

      <div class="storage-header">
        <div>
          <h3>Storage Contents</h3>
          <p>All items in storage ({{this.storage.length}} total)</p>
        </div>
        <button
          type="button"
          {{on "click" this.clearAll}}
          class="btn btn-secondary btn-small"
        >
          Clear All Storage
        </button>
      </div>

      {{#if this.allStorageItems.length}}
        <div class="storage-table-wrapper">
          <table class="storage-table">
            <thead>
              <tr>
                <th>Key</th>
                <th>Value</th>
                <th></th>
              </tr>
            </thead>
            <tbody {{flashOnUpdate}}>
              {{#each this.allStorageItems key="key" as |item|}}
                <tr>
                  <td><code>{{item.key}}</code></td>
                  <td><code>{{item.value}}</code></td>
                  <td class="delete-cell">
                    <button
                      type="button"
                      {{on "click" (fn this.removeStorageItem item.key)}}
                      class="btn-remove-table"
                      title="Remove item"
                    >
                      <svg
                        width="16"
                        height="16"
                        viewBox="0 0 16 16"
                        fill="none"
                        xmlns="http://www.w3.org/2000/svg"
                      >
                        <path
                          d="M12 4L4 12M4 4L12 12"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                        />
                      </svg>
                    </button>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      {{else}}
        <p class="empty-storage">No items in storage</p>
      {{/if}}

      <div class="note demo-note">
        <strong>💡 Try it:</strong>
        Open this page in multiple tabs or refresh the page - your data
        persists! The storage is fully reactive and updates automatically across
        all instances.
      </div>

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
    </div>
  </template>
}
