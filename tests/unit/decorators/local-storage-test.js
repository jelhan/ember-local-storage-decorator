import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';
import localStorage, {
  clearLocalStorageCache,
} from 'ember-local-storage-decorator';

module('Unit | Decorator | @localStorage', function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    window.localStorage.clear();
    clearLocalStorageCache();
  });

  module('default values', function () {
    test('it defaults to null', function (assert) {
      const klass = new (class {
        @localStorage() foo;
      })();

      assert.equal(klass.foo, null);
    });

    test('user can provide a default value', function (assert) {
      const klass = new (class {
        @localStorage() foo = 'bar';
      })();

      assert.equal(klass.foo, 'bar');
    });
  });

  module('optional parentheses', function () {
    test('it can be invoked without parentheses', function (assert) {
      const klass = new (class {
        @localStorage foo = 'no parentheses';
      })();

      assert.equal(klass.foo, 'no parentheses');
    });
  });

  module('getter', function () {
    test('picks up simple value from local storage', function (assert) {
      window.localStorage.setItem('foo', JSON.stringify('baz'));

      const klass = new (class {
        @localStorage() foo;
      })();

      assert.equal(klass.foo, 'baz');
    });

    test('picks up complex value from local storage', function (assert) {
      window.localStorage.setItem('foo', JSON.stringify([{ bar: 'baz' }]));

      const klass = new (class {
        @localStorage() foo;
      })();

      assert.deepEqual(klass.foo, [{ bar: 'baz' }]);
      assert.ok(Object.isFrozen(klass.foo), 'freezes complex value');
      assert.ok(Object.isFrozen(klass.foo[0]), 'deep freezes complex value');
    });

    test('supports custom local storage key', function (assert) {
      window.localStorage.setItem('bar', JSON.stringify('baz'));

      const klass = new (class {
        @localStorage('bar') foo;
      })();

      assert.equal(klass.foo, 'baz');
    });
  });

  module('setter', function () {
    test('user can set a simple value', function (assert) {
      const klass = new (class {
        @localStorage() foo;
      })();

      klass.foo = 'bar';
      assert.equal(klass.foo, 'bar');
    });

    test('user can set a complex value', function (assert) {
      const klass = new (class {
        @localStorage() foo;
      })();

      klass.foo = [{ bar: 'baz' }];
      assert.deepEqual(klass.foo, [{ bar: 'baz' }]);
    });

    test('persistes simple value in local storage', function (assert) {
      const klass = new (class {
        @localStorage() foo;
      })();

      klass.foo = 'baz';
      assert.equal(JSON.parse(window.localStorage.getItem('foo')), 'baz');
    });

    test('persists complex value in local storage', function (assert) {
      const klass = new (class {
        @localStorage() foo;
      })();

      const value = [{ bar: 'baz' }];

      klass.foo = value;
      assert.deepEqual(JSON.parse(window.localStorage.getItem('foo')), value);
      assert.ok(Object.isFrozen(klass.foo), 'object is frozen');
      assert.ok(Object.isFrozen(klass.foo[0]), 'object is deep frozen');
      assert.notOk(klass.foo === value, 'object is a copy of the one set');
      assert.notOk(Object.isFrozen(value), 'original object is not mutated');
    });

    test('supports custom local storage key', function (assert) {
      const klass = new (class {
        @localStorage('bar') foo;
      })();

      klass.foo = 'baz';
      assert.equal(JSON.parse(window.localStorage.getItem('bar')), 'baz');
    });
  });

  module('external changes', function () {
    test('picks up changes caused by another class', function (assert) {
      const klassA = new (class {
        @localStorage() foo;
      })();
      const klassB = new (class {
        @localStorage() foo;
      })();

      klassA.foo = 'bar';
      assert.equal(klassB.foo, 'bar');
    });

    test('picks up changes caused by other tabs', async function (assert) {
      const klass = new (class {
        @localStorage() foo;
      })();

      // assert initial state
      assert.equal(klass.foo, null);

      // act: simulate a change in another tab
      const newValue = JSON.stringify('bar');
      window.localStorage.setItem('foo', newValue);
      window.dispatchEvent(
        new StorageEvent('storage', { key: 'foo', oldValue: null, newValue })
      );

      // assert
      assert.equal(klass.foo, 'bar');
    });
  });
});
