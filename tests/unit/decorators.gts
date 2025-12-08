/* eslint-disable @typescript-eslint/no-explicit-any */
import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';
import {
  localStorage,
  sessionStorage,
  clearLocalStorageCache,
  clearSessionStorageCache,
  initializeLocalStorageKey,
  initializeSessionStorageKey,
  DEFAULT_PREFIX,
} from '#src/index.ts';

const storageTypes = [
  {
    name: 'localStorage',
    decorator: localStorage,
    storage: window.localStorage,
    clearCache: clearLocalStorageCache,
    initializeKey: initializeLocalStorageKey,
  },
  {
    name: 'sessionStorage',
    decorator: sessionStorage,
    storage: window.sessionStorage,
    clearCache: clearSessionStorageCache,
    initializeKey: initializeSessionStorageKey,
  },
] as const;

storageTypes.forEach(
  ({ name, decorator, storage, clearCache, initializeKey }) => {
    module(`Unit | Decorator | @${name}`, function (hooks) {
      setupTest(hooks);

      hooks.beforeEach(function () {
        storage.clear();
        clearCache();
      });

      module('default values', function () {
        test('it defaults to null', function (assert) {
          class TestClass {
            @decorator foo: any;
          }

          const klass = new TestClass();

          assert.equal(klass.foo, null);
        });

        test('user can provide a default value', function (assert) {
          class TestClass {
            @decorator foo: any = 'bar';
          }
          const klass = new TestClass();

          assert.equal(klass.foo, 'bar');
        });
      });

      module('optional parentheses', function () {
        test('it can be invoked with parentheses', function (assert) {
          class TestClass {
            @decorator() foo: any = 'with parentheses';
          }
          const klass = new TestClass();

          assert.equal(klass.foo, 'with parentheses');
        });
      });

      module('getter', function () {
        test(`picks up simple value from ${name}`, function (assert) {
          storage.setItem(`${DEFAULT_PREFIX}:foo`, JSON.stringify('baz'));

          class TestClass {
            @decorator foo: any;
          }

          const klass = new TestClass();

          assert.equal(klass.foo, 'baz');
        });

        test(`picks up complex value from ${name}`, function (assert) {
          storage.setItem(
            `${DEFAULT_PREFIX}:foo`,
            JSON.stringify([{ bar: 'baz' }]),
          );

          class TestClass {
            @decorator foo: any;
          }

          const klass = new TestClass();

          assert.deepEqual(klass.foo, [{ bar: 'baz' }]);
          assert.ok(Object.isFrozen(klass.foo), 'freezes complex value');
          assert.ok(
            Object.isFrozen((klass.foo as unknown[])[0]),
            'deep freezes complex value',
          );
        });

        test(`supports custom ${name} key`, function (assert) {
          storage.setItem(`${DEFAULT_PREFIX}:bar`, JSON.stringify('baz'));

          class TestClassWithCustomKey {
            @decorator('bar') foo: any;
          }

          const klass = new TestClassWithCustomKey();

          assert.equal(klass.foo, 'baz');
        });
      });

      module('setter', function () {
        test('user can set a simple value', function (assert) {
          class TestClass {
            @decorator foo: any;
          }

          const klass = new TestClass();

          klass.foo = 'bar';
          assert.equal(klass.foo, 'bar');
        });

        test('user can set a complex value', function (assert) {
          class TestClass {
            @decorator foo: any;
          }

          const klass = new TestClass();

          klass.foo = [{ bar: 'baz' }];
          assert.deepEqual(klass.foo, [{ bar: 'baz' }]);
        });

        test(`persists simple value in ${name}`, function (assert) {
          class TestClass {
            @decorator foo: any;
          }

          const klass = new TestClass();

          klass.foo = 'baz';
          assert.equal(
            JSON.parse(storage.getItem(`${DEFAULT_PREFIX}:foo`)!),
            'baz',
          );
        });

        test(`persists complex value in ${name}`, function (assert) {
          class TestClass {
            @decorator foo: any;
          }

          const klass = new TestClass();

          const value = [{ bar: 'baz' }];

          klass.foo = value;
          assert.deepEqual(
            JSON.parse(storage.getItem(`${DEFAULT_PREFIX}:foo`)!),
            value,
          );
          assert.ok(Object.isFrozen(klass.foo), 'object is frozen');
          assert.ok(
            Object.isFrozen((klass.foo as unknown[])[0]),
            'object is deep frozen',
          );
          assert.notOk(klass.foo === value, 'object is a copy of the one set');
          assert.notOk(
            Object.isFrozen(value),
            'original object is not mutated',
          );
        });

        test(`supports custom ${name} key`, function (assert) {
          class TestClassWithCustomKey {
            @decorator('bar') foo: any;
          }

          const klass = new TestClassWithCustomKey();

          klass.foo = 'baz';

          assert.equal(
            JSON.parse(storage.getItem(`${DEFAULT_PREFIX}:bar`)!),
            'baz',
          );
        });
      });

      module('external changes', function () {
        test('picks up changes caused by another class', function (assert) {
          class TestClass {
            @decorator foo: any;
          }

          const klassA = new TestClass();
          const klassB = new TestClass();

          klassA.foo = 'bar';
          assert.equal(klassB.foo, 'bar');
        });

        test('picks up changes caused by other tabs', function (assert) {
          class TestClass {
            @decorator foo: any;
          }
          const klass = new TestClass();

          // assert initial state
          assert.equal(klass.foo, null);

          // act: simulate a change in another tab
          const newValue = JSON.stringify('bar');
          storage.setItem(`${DEFAULT_PREFIX}:foo`, newValue);
          window.dispatchEvent(
            new StorageEvent('storage', {
              key: 'foo',
              oldValue: null,
              newValue,
            }),
          );

          // assert
          assert.equal(klass.foo, 'bar');
        });
      });

      module('test support', function () {
        test(`developer can reinitialize a ${name} key in tests`, function (assert) {
          // create a class, which will be used between multiple tests runs
          class Foo {
            @decorator foo: undefined | string;
          }

          // use the class in first test
          assert.equal(new Foo().foo, null);

          // reset storage cache as developer is expected to do in beforeEach hook
          storage.clear();
          clearCache();

          // arrange storage value for another test
          storage.setItem(`${DEFAULT_PREFIX}:foo`, JSON.stringify('bar'));
          initializeKey('foo');

          // use the class in second test
          assert.equal(new Foo().foo, 'bar');
        });
      });
    });
  },
);
