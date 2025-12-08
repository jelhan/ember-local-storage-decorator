import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import { TrackedStorage, DEFAULT_PREFIX } from '#src/index.ts';
import Component from '@glimmer/component';
import { on } from '@ember/modifier';

module('Integration | TrackedStorage (sessionStorage)', function (hooks) {
  setupRenderingTest(hooks);

  let storage: TrackedStorage;

  hooks.beforeEach(function () {
    window.sessionStorage.clear();
    storage = new TrackedStorage(window.sessionStorage);
  });

  test('basic get and set operations work', async function (assert) {
    class TestComponent extends Component {
      storage = storage;

      updateValue = () => {
        this.storage.setItem('test', 'hello');
      };

      <template>
        <div data-test-value>{{this.storage.getItem "test"}}</div>
        <button type="button" {{on "click" this.updateValue}} data-test-btn></button>
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
        <button type="button" {{on "click" this.increment}} data-test-btn></button>
      </template>
    }

    await render(<template><TestComponent /></template>);
    assert.dom('[data-test-value]').hasText('0');

    await click('[data-test-btn]');
    assert.dom('[data-test-value]').hasText('1');

    await click('[data-test-btn]');
    assert.dom('[data-test-value]').hasText('2');
  });

  test('persists to underlying storage', function (assert) {
    storage.setItem('persisted', 'test value');

    assert.equal(
      JSON.parse(window.sessionStorage.getItem(`${DEFAULT_PREFIX}:persisted`)!),
      'test value',
    );
  });  test('loads existing values from storage', function (assert) {
    window.sessionStorage.setItem(`${DEFAULT_PREFIX}:existing`, JSON.stringify('preexisting'));

    const newStorage = new TrackedStorage(window.sessionStorage);

    assert.equal(newStorage.getItem('existing'), 'preexisting');
  });

  test('setting value to null removes it from storage', function (assert) {
    storage.setItem('test', 'initial value');
    assert.equal(storage.getItem('test'), 'initial value');
    assert.ok(window.sessionStorage.getItem(`${DEFAULT_PREFIX}:test`));

    storage.setItem('test', null);
    assert.equal(storage.getItem('test'), null);
    assert.equal(window.sessionStorage.getItem(`${DEFAULT_PREFIX}:test`), null);
  });

  test('setting value to undefined removes it from storage', function (assert) {
    storage.setItem('test', 'initial value');
    assert.equal(storage.getItem('test'), 'initial value');
    assert.ok(window.sessionStorage.getItem(`${DEFAULT_PREFIX}:test`));

    storage.setItem('test', undefined);
    assert.equal(storage.getItem('test'), null);
    assert.equal(window.sessionStorage.getItem(`${DEFAULT_PREFIX}:test`), null);
  });
});
