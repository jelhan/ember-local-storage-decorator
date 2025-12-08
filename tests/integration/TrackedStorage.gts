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

      await click('[data-test-btn]');
      assert.dom('[data-test-value]').hasText('2');

      if (name === 'localStorage') {
        await click('[data-test-btn]');
        assert.dom('[data-test-value]').hasText('3');
      }
    });

    if (name === 'localStorage') {
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
    }

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
  });
});
