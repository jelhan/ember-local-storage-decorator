/* eslint-disable @typescript-eslint/no-explicit-any */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import {
  localStorage,
  sessionStorage,
  clearLocalStorageCache,
  clearSessionStorageCache,
} from '#src/index.ts';
import { DEFAULT_PREFIX } from '#src/TrackedStorage.ts';
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

const storageTypes = [
  {
    name: 'localStorage',
    decorator: localStorage,
    storage: window.localStorage,
    clearCache: clearLocalStorageCache,
  },
  {
    name: 'sessionStorage',
    decorator: sessionStorage,
    storage: window.sessionStorage,
    clearCache: clearSessionStorageCache,
  },
] as const;

storageTypes.forEach(({ name, decorator, storage, clearCache }) => {
  module(
    `Integration | Component | test-component (${name})`,
    function (hooks) {
      setupRenderingTest(hooks);

      hooks.beforeEach(function () {
        storage.clear();
        clearCache();
      });

      test('it works inside a component', async function (assert) {
        class TestComponent extends Component<TestComponentSignature> {
          @decorator foo?: string;

          @decorator bar?: string;

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

        await render(<template><TestComponent /></template>);
        assert.dom().hasText('');
        assert.equal(
          JSON.parse(storage.getItem(`${DEFAULT_PREFIX}:foo`)!),
          null,
        );

        await click('button');
        assert.dom().hasText('foo');
        assert.equal(
          JSON.parse(storage.getItem(`${DEFAULT_PREFIX}:foo`)!),
          'foo',
        );
      });

      test('setting one property does not invalidate another', async function (assert) {
        class TestComponent extends Component<TestComponentSignature> {
          @decorator foo?: string;

          @decorator bar?: string;

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
    },
  );
});
