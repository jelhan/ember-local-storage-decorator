/* eslint-disable @typescript-eslint/no-explicit-any */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import localStorage, { clearLocalStorageCache } from '#src/index.ts';
import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';

const didUpdate = (callback: (v: any) => void, b: string | undefined) => {
  if (b === undefined) {
    return;
  }
  callback(b);
};

interface TestComponentSignature {
  Element: HTMLDivElement;
  Args: {
    onInvalidation?: (property: string, value: any) => void;
  };
}
export default class TestComponent extends Component<TestComponentSignature> {
  @localStorage foo?: string;

  @localStorage bar?: string;

  updateFoo = () => {
    this.foo = 'foo';
  };

  <template>
    {{this.foo}}

    <button type="button" {{on "click" this.updateFoo}}></button>

    {{#if @onInvalidation}}
      {{didUpdate (fn @onInvalidation "foo") this.foo}}
      {{didUpdate (fn @onInvalidation "bar") this.bar}}
    {{/if}}
  </template>
}

module('Integration | Component | test-component', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    window.localStorage.clear();
    clearLocalStorageCache();
  });

  test('it works inside a component', async function (assert) {
    await render(<template><TestComponent /></template>);
    assert.dom().hasText('');
    assert.equal(JSON.parse(window.localStorage.getItem('foo')!), null);

    await click('button');
    assert.dom().hasText('foo');
    assert.equal(JSON.parse(window.localStorage.getItem('foo')!), 'foo');
  });

  test('setting one property does not invalidate another', async function (assert) {
    let invalidationCounter = {
      foo: 0,
      bar: 0,
    };

    class State {
      invalidationTracker = (property: string) => {
        invalidationCounter[property as keyof typeof invalidationCounter]++;
      };
    }

    const state = new State();

    await render(
      <template>
        <TestComponent @onInvalidation={{state.invalidationTracker}} />
      </template>,
    );
    // change foo
    await click('button');
    assert.deepEqual(invalidationCounter, { foo: 1, bar: 0 });
  });
});
