import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import { hbs } from 'ember-cli-htmlbars';
import { clearLocalStorageCache } from 'ember-local-storage-decorator';

module('Integration | Component | test-component', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    window.localStorage.clear();
    clearLocalStorageCache();
  });

  test('it works inside a component', async function (assert) {
    await render(hbs`<TestComponent />`);
    assert.dom().hasText('');
    assert.equal(JSON.parse(window.localStorage.getItem('foo')!), null);

    await click('button');
    assert.dom().hasText('foo');
    assert.equal(JSON.parse(window.localStorage.getItem('foo')!), 'foo');
  });

  test('setting one property does not invalidate another', async function (assert) {
    const invalidationCounter = {
      foo: 0,
      bar: 0,
    };
    this.set(
      'invalidationTracker',
      (property: keyof typeof invalidationCounter) => {
        invalidationCounter[property]++;
      }
    );
    await render(
      hbs`<TestComponent @onInvalidation={{this.invalidationTracker}} />`
    );
    // change foo
    await click('button');
    assert.deepEqual(invalidationCounter, { foo: 1, bar: 0 });
  });
});
