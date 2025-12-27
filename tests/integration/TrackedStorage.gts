import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import { TrackedStorage, DEFAULT_PREFIX } from '#src/index.ts';
import Component from '@glimmer/component';
import { on } from '@ember/modifier';

const storageTypes = [
  {
    name: 'localStorage',
    storage: window.localStorage,
  },
  {
    name: 'sessionStorage',
    storage: window.sessionStorage,
  },
] as const;

storageTypes.forEach(({ name, storage: windowStorage }) => {
  module(`Integration | TrackedStorage (${name})`, function (hooks) {
    setupRenderingTest(hooks);

    let storage: TrackedStorage;

    hooks.beforeEach(function () {
      windowStorage.clear();
      storage = new TrackedStorage(windowStorage);
      storage.clearCache();
    });

    test('basic get and set operations work', async function (assert) {
      class TestComponent extends Component {
        storage = storage;

        updateValue = () => {
          this.storage.setItem('test', 'hello');
        };

        <template>
          <div data-test-value>{{this.storage.getItem "test"}}</div>
          <button
            type="button"
            {{on "click" this.updateValue}}
            data-test-btn
          ></button>
        </template>
      }

      await render(<template><TestComponent /></template>);
      assert.dom('[data-test-value]').hasText('');

      await click('[data-test-btn]');
      assert.dom('[data-test-value]').hasText('hello');
    });

    test('updates are reactive', async function (assert) {
      storage.setItem('counter', 0);

      class TestComponent extends Component {
        storage = storage;

        increment = () => {
          const current = this.storage.getItem<number>('counter') || 0;
          this.storage.setItem('counter', current + 1);
        };

        <template>
          <div data-test-value>{{this.storage.getItem "counter"}}</div>
          <button
            type="button"
            {{on "click" this.increment}}
            data-test-btn
          ></button>
        </template>
      }

      await render(<template><TestComponent /></template>);
      assert.dom('[data-test-value]').hasText('0');

      await click('[data-test-btn]');
      assert.dom('[data-test-value]').hasText('1');
    });

    test('works with complex objects', async function (assert) {
      storage.setItem('user', { name: 'Alice', age: 30 });

      class TestComponent extends Component {
        storage = storage;

        get user() {
          return this.storage.getItem<{ name: string; age: number }>('user');
        }

        updateUser = () => {
          this.storage.setItem('user', { name: 'Bob', age: 25 });
        };

        <template>
          <div data-test-name>{{this.user.name}}</div>
          <div data-test-age>{{this.user.age}}</div>
          <button
            type="button"
            {{on "click" this.updateUser}}
            data-test-btn
          ></button>
        </template>
      }

      await render(<template><TestComponent /></template>);
      assert.dom('[data-test-name]').hasText('Alice');
      assert.dom('[data-test-age]').hasText('30');

      await click('[data-test-btn]');
      assert.dom('[data-test-name]').hasText('Bob');
      assert.dom('[data-test-age]').hasText('25');
    });

    test('multiple keys are independent', async function (assert) {
      storage.setItem('foo', 'initial foo');
      storage.setItem('bar', 'initial bar');

      class TestComponent extends Component {
        storage = storage;

        updateFoo = () => {
          this.storage.setItem('foo', 'updated foo');
        };

        updateBar = () => {
          this.storage.setItem('bar', 'updated bar');
        };

        <template>
          <div data-test-foo>{{this.storage.getItem "foo"}}</div>
          <div data-test-bar>{{this.storage.getItem "bar"}}</div>
          <button
            type="button"
            {{on "click" this.updateFoo}}
            data-test-foo-btn
          ></button>
          <button
            type="button"
            {{on "click" this.updateBar}}
            data-test-bar-btn
          ></button>
        </template>
      }

      await render(<template><TestComponent /></template>);
      assert.dom('[data-test-foo]').hasText('initial foo');
      assert.dom('[data-test-bar]').hasText('initial bar');

      await click('[data-test-foo-btn]');
      assert.dom('[data-test-foo]').hasText('updated foo');
      assert.dom('[data-test-bar]').hasText('initial bar');

      await click('[data-test-bar-btn]');
      assert.dom('[data-test-foo]').hasText('updated foo');
      assert.dom('[data-test-bar]').hasText('updated bar');
    });

    test('removeItem works', async function (assert) {
      storage.setItem('temp', 'value');

      class TestComponent extends Component {
        storage = storage;

        remove = () => {
          this.storage.removeItem('temp');
        };

        <template>
          <div data-test-value>{{this.storage.getItem "temp"}}</div>
          <button
            type="button"
            {{on "click" this.remove}}
            data-test-btn
          ></button>
        </template>
      }

      await render(<template><TestComponent /></template>);
      assert.dom('[data-test-value]').hasText('value');

      await click('[data-test-btn]');
      assert.dom('[data-test-value]').hasText('');
    });

    test('clear removes all items', async function (assert) {
      storage.setItem('key1', 'value1');
      storage.setItem('key2', 'value2');

      class TestComponent extends Component {
        storage = storage;

        clearAll = () => {
          this.storage.clear();
        };

        <template>
          <div data-test-key1>{{this.storage.getItem "key1"}}</div>
          <div data-test-key2>{{this.storage.getItem "key2"}}</div>
          <button
            type="button"
            {{on "click" this.clearAll}}
            data-test-btn
          ></button>
        </template>
      }

      await render(<template><TestComponent /></template>);
      assert.dom('[data-test-key1]').hasText('value1');
      assert.dom('[data-test-key2]').hasText('value2');

      await click('[data-test-btn]');
      assert.dom('[data-test-key1]').hasText('');
      assert.dom('[data-test-key2]').hasText('');
    });

    test('objects are frozen', function (assert) {
      const data = { items: ['a', 'b'] };
      storage.setItem('data', data);

      const retrieved = storage.getItem<{ items: string[] }>('data');
      assert.ok(Object.isFrozen(retrieved));
      assert.ok(Object.isFrozen(retrieved?.items));
    });

    test('persists to underlying storage', function (assert) {
      storage.setItem('persisted', 'test value');

      assert.equal(
        JSON.parse(windowStorage.getItem(`${DEFAULT_PREFIX}:persisted`)!),
        'test value',
      );
    });

    test('loads existing values from storage', function (assert) {
      windowStorage.setItem(
        `${DEFAULT_PREFIX}:existing`,
        JSON.stringify('preexisting'),
      );

      const newStorage = new TrackedStorage(windowStorage);

      assert.equal(newStorage.getItem('existing'), 'preexisting');
    });

    test('item that is null is still reactive', async function (assert) {
      windowStorage.setItem(`${DEFAULT_PREFIX}:nullable`, JSON.stringify(null));
      class TestComponent extends Component {
        storage = storage;

        setValue = () => {
          this.storage.setItem('nullable', 'value');
        };

        <template>
          <div data-test-value>{{this.storage.getItem "nullable"}}</div>
          <button
            type="button"
            {{on "click" this.setValue}}
            data-test-btn
          ></button>
        </template>
      }

      await render(<template><TestComponent /></template>);
      assert.dom('[data-test-value]').hasText('');

      await click('[data-test-btn]');
      assert.dom('[data-test-value]').hasText('value');
    });

    test('item that is uninitialized is still reactive', async function (assert) {
      windowStorage.setItem(
        `${DEFAULT_PREFIX}:nullable`,
        JSON.stringify('test'),
      );
      class TestComponent extends Component {
        storage = storage;

        setValue = () => {
          this.storage.setItem('nullable', 'value');
        };

        <template>
          <div data-test-value>{{this.storage.getItem "nullable"}}</div>
          <button
            type="button"
            {{on "click" this.setValue}}
            data-test-btn
          ></button>
        </template>
      }

      await render(<template><TestComponent /></template>);
      assert.dom('[data-test-value]').hasText('test');

      await click('[data-test-btn]');
      assert.dom('[data-test-value]').hasText('value');
    });

    test('setting value to null removes it from storage', function (assert) {
      storage.setItem('test', 'initial value');
      assert.equal(storage.getItem('test'), 'initial value');
      assert.ok(windowStorage.getItem(`${DEFAULT_PREFIX}:test`));

      storage.setItem('test', null);
      assert.equal(storage.getItem('test'), null);
      assert.equal(windowStorage.getItem(`${DEFAULT_PREFIX}:test`), null);
    });

    test('setting value to undefined removes it from storage', function (assert) {
      storage.setItem('test', 'initial value');
      assert.equal(storage.getItem('test'), 'initial value');
      assert.ok(windowStorage.getItem(`${DEFAULT_PREFIX}:test`));

      storage.setItem('test', undefined);
      assert.equal(storage.getItem('test'), null);
      assert.equal(windowStorage.getItem(`${DEFAULT_PREFIX}:test`), null);
    });

    test('multiple instances sharing cache trigger reactivity in both', async function (assert) {
      const storage1 = new TrackedStorage(windowStorage);
      const storage2 = new TrackedStorage(windowStorage);

      storage1.setItem('shared', 'initial');

      class Component1 extends Component {
        storage = storage1;

        <template>
          <div data-test-component1>{{this.storage.getItem "shared"}}</div>
        </template>
      }

      class Component2 extends Component {
        storage = storage2;

        updateValue = () => {
          this.storage.setItem('shared', 'updated by storage2');
        };

        <template>
          <div data-test-component2>{{this.storage.getItem "shared"}}</div>
          <button
            type="button"
            {{on "click" this.updateValue}}
            data-test-update
          ></button>
        </template>
      }

      await render(
        <template>
          <Component1 />
          <Component2 />
        </template>,
      );

      // Both components should see the initial value
      assert.dom('[data-test-component1]').hasText('initial');
      assert.dom('[data-test-component2]').hasText('initial');

      // Update via storage2
      await click('[data-test-update]');

      // Both components should immediately see the updated value
      assert
        .dom('[data-test-component1]')
        .hasText('updated by storage2', 'component1 sees update from storage2');
      assert
        .dom('[data-test-component2]')
        .hasText('updated by storage2', 'component2 sees its own update');
    });

    test('instances with different prefixes remain isolated in rendering', async function (assert) {
      const storageA = new TrackedStorage(windowStorage, 'prefixA');
      const storageB = new TrackedStorage(windowStorage, 'prefixB');

      storageA.setItem('value', 'A');
      storageB.setItem('value', 'B');

      class ComponentA extends Component {
        storage = storageA;

        updateValue = () => {
          this.storage.setItem('value', 'A updated');
        };

        <template>
          <div data-test-a>{{this.storage.getItem "value"}}</div>
          <button
            type="button"
            {{on "click" this.updateValue}}
            data-test-update-a
          ></button>
        </template>
      }

      class ComponentB extends Component {
        storage = storageB;

        <template>
          <div data-test-b>{{this.storage.getItem "value"}}</div>
        </template>
      }

      await render(
        <template>
          <ComponentA />
          <ComponentB />
        </template>,
      );

      // Each component sees its own value
      assert.dom('[data-test-a]').hasText('A');
      assert.dom('[data-test-b]').hasText('B');

      // Update storageA
      await click('[data-test-update-a]');

      // Only componentA should update
      assert
        .dom('[data-test-a]')
        .hasText('A updated', 'prefixA component updated');
      assert.dom('[data-test-b]').hasText('B', 'prefixB component unchanged');
    });

    test('removing item in one instance updates all components', async function (assert) {
      const storage1 = new TrackedStorage(windowStorage);
      const storage2 = new TrackedStorage(windowStorage);

      storage1.setItem('removable', 'present');

      class Component1 extends Component {
        storage = storage1;

        <template>
          <div data-test-component1>{{this.storage.getItem "removable"}}</div>
        </template>
      }

      class Component2 extends Component {
        storage = storage2;

        removeValue = () => {
          this.storage.removeItem('removable');
        };

        <template>
          <div data-test-component2>{{this.storage.getItem "removable"}}</div>
          <button
            type="button"
            {{on "click" this.removeValue}}
            data-test-remove
          ></button>
        </template>
      }

      await render(
        <template>
          <Component1 />
          <Component2 />
        </template>,
      );

      // Both components should see the value
      assert.dom('[data-test-component1]').hasText('present');
      assert.dom('[data-test-component2]').hasText('present');

      // Remove via storage2
      await click('[data-test-remove]');

      // Both components should show empty (null renders as empty)
      assert
        .dom('[data-test-component1]')
        .hasText('', 'component1 sees removal');
      assert
        .dom('[data-test-component2]')
        .hasText('', 'component2 sees removal');
    });

    test('clear in one instance updates all components', async function (assert) {
      const storage1 = new TrackedStorage(windowStorage);
      const storage2 = new TrackedStorage(windowStorage);

      storage1.setItem('key1', 'value1');
      storage1.setItem('key2', 'value2');

      class Component1 extends Component {
        storage = storage1;

        <template>
          <div data-test-key1>{{this.storage.getItem "key1"}}</div>
          <div data-test-key2>{{this.storage.getItem "key2"}}</div>
          <div data-test-length1>{{this.storage.length}}</div>
        </template>
      }

      class Component2 extends Component {
        storage = storage2;

        clearAll = () => {
          this.storage.clear();
        };

        <template>
          <div data-test-length2>{{this.storage.length}}</div>
          <button
            type="button"
            {{on "click" this.clearAll}}
            data-test-clear
          ></button>
        </template>
      }

      await render(
        <template>
          <Component1 />
          <Component2 />
        </template>,
      );

      // Initial state
      assert.dom('[data-test-key1]').hasText('value1');
      assert.dom('[data-test-key2]').hasText('value2');
      assert.dom('[data-test-length1]').hasText('2');
      assert.dom('[data-test-length2]').hasText('2');

      // Clear via storage2
      await click('[data-test-clear]');

      // All components should reflect the cleared state
      assert.dom('[data-test-key1]').hasText('', 'key1 cleared in component1');
      assert.dom('[data-test-key2]').hasText('', 'key2 cleared in component1');
      assert
        .dom('[data-test-length1]')
        .hasText('0', 'length updated in component1');
      assert
        .dom('[data-test-length2]')
        .hasText('0', 'length updated in component2');
    });
  });
});
