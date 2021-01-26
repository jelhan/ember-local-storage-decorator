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
    assert.equal(JSON.parse(window.localStorage.getItem('baz')), null);

    await click('button');
    assert.dom().hasText('baz');
    assert.equal(JSON.parse(window.localStorage.getItem('baz')), 'baz');
  });
});
