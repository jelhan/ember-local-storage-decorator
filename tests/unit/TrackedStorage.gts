import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';
import { TrackedStorage, DEFAULT_PREFIX } from '#src/index.ts';

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
  module(`Unit | TrackedStorage (${name})`, function (hooks) {
    setupTest(hooks);

    let storage: TrackedStorage;

    hooks.beforeEach(function () {
      windowStorage.clear();
      storage = new TrackedStorage(windowStorage);
    });

    module('constructor', function () {
      test('initializes with default prefix', function (assert) {
        assert.ok(storage, 'storage instance created');
      });

      test('initializes with custom prefix', function (assert) {
        const customStorage = new TrackedStorage(
          windowStorage,
          'custom_prefix',
        );
        customStorage.setItem('test', 'value');

        assert.equal(
          windowStorage.getItem('custom_prefix:test'),
          JSON.stringify('value'),
          'uses custom prefix',
        );
      });

      test('loads existing prefixed keys on initialization', function (assert) {
        windowStorage.setItem(
          `${DEFAULT_PREFIX}:existing1`,
          JSON.stringify('value1'),
        );
        windowStorage.setItem(
          `${DEFAULT_PREFIX}:existing2`,
          JSON.stringify('value2'),
        );
        windowStorage.setItem('non_prefixed', JSON.stringify('ignored'));

        const newStorage = new TrackedStorage(windowStorage);

        assert.equal(
          newStorage.getItem('existing1'),
          'value1',
          'loads prefixed key 1',
        );
        assert.equal(
          newStorage.getItem('existing2'),
          'value2',
          'loads prefixed key 2',
        );
        assert.equal(
          newStorage.getItem('non_prefixed'),
          null,
          'ignores non-prefixed keys',
        );
      });

      test('only loads keys matching its prefix', function (assert) {
        windowStorage.setItem('other_prefix:key1', JSON.stringify('value1'));
        windowStorage.setItem(
          `${DEFAULT_PREFIX}:key2`,
          JSON.stringify('value2'),
        );

        const newStorage = new TrackedStorage(windowStorage);

        assert.equal(newStorage.getItem('key1'), null, 'ignores other prefix');
        assert.equal(
          newStorage.getItem('key2'),
          'value2',
          'loads matching prefix',
        );
      });
    });

    module('shared cache', function () {
      test('multiple instances with same storage and prefix share cache', function (assert) {
        const storage1 = new TrackedStorage(windowStorage);
        const storage2 = new TrackedStorage(windowStorage);

        storage1.setItem('shared_key', 'value1');

        // storage2 should immediately see the value without storage event
        assert.equal(
          storage2.getItem('shared_key'),
          'value1',
          'second instance sees value from first instance',
        );

        storage2.setItem('shared_key', 'value2');

        // storage1 should immediately see the updated value
        assert.equal(
          storage1.getItem('shared_key'),
          'value2',
          'first instance sees update from second instance',
        );
      });

      test('instances with different prefixes do not share cache', function (assert) {
        const storage1 = new TrackedStorage(windowStorage, 'prefix1');
        const storage2 = new TrackedStorage(windowStorage, 'prefix2');

        storage1.setItem('key', 'value1');
        storage2.setItem('key', 'value2');

        assert.equal(
          storage1.getItem('key'),
          'value1',
          'prefix1 instance has its own value',
        );
        assert.equal(
          storage2.getItem('key'),
          'value2',
          'prefix2 instance has its own value',
        );

        // Verify they created separate keys in underlying storage
        assert.equal(
          windowStorage.getItem('prefix1:key'),
          JSON.stringify('value1'),
          'prefix1 key exists in storage',
        );
        assert.equal(
          windowStorage.getItem('prefix2:key'),
          JSON.stringify('value2'),
          'prefix2 key exists in storage',
        );
      });

      test('localStorage and sessionStorage do not share cache', function (assert) {
        const localStorage = new TrackedStorage(
          window.localStorage,
          'test_prefix',
        );
        const sessionStorage = new TrackedStorage(
          window.sessionStorage,
          'test_prefix',
        );

        window.localStorage.clear();
        window.sessionStorage.clear();

        localStorage.setItem('key', 'local_value');
        sessionStorage.setItem('key', 'session_value');

        assert.equal(
          localStorage.getItem('key'),
          'local_value',
          'localStorage has its own value',
        );
        assert.equal(
          sessionStorage.getItem('key'),
          'session_value',
          'sessionStorage has its own value',
        );
      });

      test('new instance syncs with storage state when cache exists', function (assert) {
        const storage1 = new TrackedStorage(windowStorage);

        storage1.setItem('key1', 'value1');
        storage1.setItem('key2', 'value2');

        // Manually clear underlying storage (simulating external clear)
        windowStorage.clear();

        // Create new instance - should sync with empty storage
        const storage2 = new TrackedStorage(windowStorage);

        assert.equal(
          storage2.getItem('key1'),
          null,
          'new instance does not see cleared key1',
        );
        assert.equal(
          storage2.getItem('key2'),
          null,
          'new instance does not see cleared key2',
        );
        assert.equal(storage2.length, 0, 'new instance has zero length');

        // storage1 should also reflect the cleared state due to shared cache
        assert.equal(
          storage1.getItem('key1'),
          null,
          'original instance also sees cleared state',
        );
        assert.equal(storage1.length, 0, 'original instance has zero length');
      });

      test('new instance picks up keys added externally', function (assert) {
        const storage1 = new TrackedStorage(windowStorage);

        // Manually add key to underlying storage (simulating external addition)
        windowStorage.setItem(
          `${DEFAULT_PREFIX}:external_key`,
          JSON.stringify('external_value'),
        );

        // Create new instance - should pick up the external key
        const storage2 = new TrackedStorage(windowStorage);

        assert.equal(
          storage2.getItem('external_key'),
          'external_value',
          'new instance sees externally added key',
        );

        // Original instance should also see it due to shared cache
        assert.equal(
          storage1.getItem('external_key'),
          'external_value',
          'original instance also sees externally added key',
        );
      });

      test('clear on one instance clears shared cache', function (assert) {
        const storage1 = new TrackedStorage(windowStorage);
        const storage2 = new TrackedStorage(windowStorage);

        storage1.setItem('key1', 'value1');
        storage2.setItem('key2', 'value2');

        assert.equal(storage1.length, 2, 'storage1 has 2 keys');
        assert.equal(storage2.length, 2, 'storage2 has 2 keys');

        storage1.clear();

        assert.equal(storage1.length, 0, 'storage1 is empty after clear');
        assert.equal(storage2.length, 0, 'storage2 is also empty');
        assert.equal(
          storage2.getItem('key1'),
          null,
          'storage2 does not see key1',
        );
        assert.equal(
          storage2.getItem('key2'),
          null,
          'storage2 does not see key2',
        );
      });

      test('managed keys do not pollute across different prefixes', function (assert) {
        const storage1 = new TrackedStorage(windowStorage, 'prefix1');
        const storage2 = new TrackedStorage(windowStorage, 'prefix2');

        storage1.setItem('key1', 'value1');
        storage1.setItem('key2', 'value2');
        storage2.setItem('keyA', 'valueA');

        assert.equal(storage1.length, 2, 'prefix1 has 2 keys');
        assert.equal(storage2.length, 1, 'prefix2 has 1 key');

        // key() should only return keys for the respective prefix
        const storage1Keys = [storage1.key(0), storage1.key(1)].sort();
        assert.deepEqual(
          storage1Keys,
          ['key1', 'key2'],
          'prefix1 returns only its keys',
        );

        assert.equal(storage2.key(0), 'keyA', 'prefix2 returns only its key');
        assert.equal(storage2.key(1), null, 'prefix2 has no second key');
      });
    });

    module('getItem', function () {
      test('returns null for non-existent keys', function (assert) {
        assert.equal(storage.getItem('nonexistent'), null);
      });

      test('retrieves simple values', function (assert) {
        storage.setItem('string', 'hello');
        storage.setItem('number', 42);
        storage.setItem('boolean', true);

        assert.equal(storage.getItem('string'), 'hello');
        assert.equal(storage.getItem('number'), 42);
        assert.equal(storage.getItem('boolean'), true);
      });

      test('retrieves complex objects', function (assert) {
        const obj = { name: 'Alice', age: 30, tags: ['a', 'b'] };
        storage.setItem('object', obj);

        assert.deepEqual(storage.getItem('object'), obj);
      });

      test('returned objects are frozen', function (assert) {
        storage.setItem('obj', { nested: { value: 42 } });
        const retrieved = storage.getItem<{ nested: { value: number } }>('obj');

        assert.ok(Object.isFrozen(retrieved));
        assert.ok(Object.isFrozen(retrieved?.nested));
      });

      test('returns null for keys from different prefix', function (assert) {
        windowStorage.setItem('other_prefix:key', JSON.stringify('value'));

        assert.equal(storage.getItem('key'), null);
      });
    });

    module('setItem', function () {
      test('stores simple values', function (assert) {
        storage.setItem('test', 'value');

        assert.equal(
          windowStorage.getItem(`${DEFAULT_PREFIX}:test`),
          JSON.stringify('value'),
        );
      });

      test('stores complex objects', function (assert) {
        const obj = { a: 1, b: [2, 3] };
        storage.setItem('test', obj);

        assert.equal(
          windowStorage.getItem(`${DEFAULT_PREFIX}:test`),
          JSON.stringify(obj),
        );
      });

      test('overwrites existing values', function (assert) {
        storage.setItem('test', 'first');
        storage.setItem('test', 'second');

        assert.equal(storage.getItem('test'), 'second');
      });

      test('setting null removes the item', function (assert) {
        storage.setItem('test', 'value');
        assert.ok(windowStorage.getItem(`${DEFAULT_PREFIX}:test`));

        storage.setItem('test', null);

        assert.equal(storage.getItem('test'), null);
        assert.equal(windowStorage.getItem(`${DEFAULT_PREFIX}:test`), null);
      });

      test('setting undefined removes the item', function (assert) {
        storage.setItem('test', 'value');
        assert.ok(windowStorage.getItem(`${DEFAULT_PREFIX}:test`));

        storage.setItem('test', undefined);

        assert.equal(storage.getItem('test'), null);
        assert.equal(windowStorage.getItem(`${DEFAULT_PREFIX}:test`), null);
      });

      test('does not interfere with non-prefixed keys', function (assert) {
        windowStorage.setItem('external_key', 'external_value');
        storage.setItem('internal_key', 'internal_value');

        assert.equal(windowStorage.getItem('external_key'), 'external_value');
        assert.equal(
          windowStorage.getItem(`${DEFAULT_PREFIX}:internal_key`),
          JSON.stringify('internal_value'),
        );
      });
    });

    module('removeItem', function () {
      test('removes existing items', function (assert) {
        storage.setItem('test', 'value');
        assert.equal(storage.getItem('test'), 'value');

        storage.removeItem('test');

        assert.equal(storage.getItem('test'), null);
        assert.equal(windowStorage.getItem(`${DEFAULT_PREFIX}:test`), null);
      });

      test('handles removing non-existent items', function (assert) {
        assert.expect(0);
        storage.removeItem('nonexistent'); // should not throw
      });

      test('only removes prefixed keys', function (assert) {
        windowStorage.setItem('external_key', 'value');
        storage.removeItem('external_key');

        assert.equal(
          windowStorage.getItem('external_key'),
          'value',
          'external key unchanged',
        );
      });
    });

    module('clear', function () {
      test('removes all prefixed items', function (assert) {
        storage.setItem('key1', 'value1');
        storage.setItem('key2', 'value2');
        storage.setItem('key3', 'value3');

        storage.clear();

        assert.equal(storage.getItem('key1'), null);
        assert.equal(storage.getItem('key2'), null);
        assert.equal(storage.getItem('key3'), null);
      });

      test('does not remove non-prefixed items', function (assert) {
        windowStorage.setItem('external_key', 'external_value');
        storage.setItem('internal_key', 'internal_value');

        storage.clear();

        assert.equal(windowStorage.getItem('external_key'), 'external_value');
        assert.equal(storage.getItem('internal_key'), null);
      });

      test('does not remove items with different prefix', function (assert) {
        windowStorage.setItem('other_prefix:key', 'value');
        storage.setItem('key', 'value');

        storage.clear();

        assert.equal(windowStorage.getItem('other_prefix:key'), 'value');
        assert.equal(storage.getItem('key'), null);
      });
    });

    module('key', function () {
      test('returns null for invalid indices', function (assert) {
        assert.equal(storage.key(-1), null);
        assert.equal(storage.key(999), null);
      });

      test('returns keys without prefix', function (assert) {
        storage.setItem('first', 'a');
        storage.setItem('second', 'b');

        const key0 = storage.key(0);
        const key1 = storage.key(1);

        assert.ok(['first', 'second'].includes(key0!), 'key 0 is valid');
        assert.ok(['first', 'second'].includes(key1!), 'key 1 is valid');
        assert.notEqual(key0, key1, 'keys are different');
      });

      test('only returns prefixed keys', function (assert) {
        windowStorage.setItem('external_key', 'external');
        storage.setItem('internal_key', 'internal');

        const key = storage.key(0);

        assert.equal(key, 'internal_key', 'returns only prefixed key');
      });

      test('length reflects only prefixed keys', function (assert) {
        windowStorage.setItem('external1', 'a');
        windowStorage.setItem('external2', 'b');
        storage.setItem('internal1', 'c');
        storage.setItem('internal2', 'd');

        assert.equal(storage.length, 2, 'length counts only prefixed keys');
      });
    });

    module('clearCache', function () {
      test('clears the internal cache', function (assert) {
        storage.setItem('test', 'value');

        // Value should be in underlying storage
        assert.ok(windowStorage.getItem(`${DEFAULT_PREFIX}:test`));

        storage.clearCache();

        // After clearCache, value should still be in underlying storage
        assert.ok(windowStorage.getItem(`${DEFAULT_PREFIX}:test`));

        // But should be reloaded from storage on next access
        assert.equal(storage.getItem('test'), 'value');
      });
    });

    module('prefix isolation', function () {
      test('multiple TrackedStorage instances with different prefixes are isolated', function (assert) {
        const storage1 = new TrackedStorage(windowStorage, 'prefix1');
        const storage2 = new TrackedStorage(windowStorage, 'prefix2');

        storage1.setItem('shared_key', 'value1');
        storage2.setItem('shared_key', 'value2');

        assert.equal(storage1.getItem('shared_key'), 'value1');
        assert.equal(storage2.getItem('shared_key'), 'value2');
        assert.equal(
          windowStorage.getItem('prefix1:shared_key'),
          JSON.stringify('value1'),
        );
        assert.equal(
          windowStorage.getItem('prefix2:shared_key'),
          JSON.stringify('value2'),
        );
      });

      test('clear only affects keys with matching prefix', function (assert) {
        const storage1 = new TrackedStorage(windowStorage, 'prefix1');
        const storage2 = new TrackedStorage(windowStorage, 'prefix2');

        storage1.setItem('key', 'value1');
        storage2.setItem('key', 'value2');

        storage1.clear();

        assert.equal(storage1.getItem('key'), null);
        assert.equal(storage2.getItem('key'), 'value2');
      });
    });

    module('edge cases', function () {
      test('handles keys with special characters', function (assert) {
        const specialKeys = [
          'key:with:colons',
          'key/with/slashes',
          'key.with.dots',
        ];

        specialKeys.forEach((key) => {
          storage.setItem(key, 'value');
          assert.equal(storage.getItem(key), 'value', `handles ${key}`);
        });
      });

      test('handles empty string key', function (assert) {
        storage.setItem('', 'value');
        assert.equal(storage.getItem(''), 'value');
      });

      test('handles empty string value', function (assert) {
        storage.setItem('test', '');
        assert.equal(storage.getItem('test'), '');
      });

      test('handles null in complex objects', function (assert) {
        storage.setItem('test', { value: null });
        assert.deepEqual(storage.getItem('test'), { value: null });
      });

      test('handles arrays', function (assert) {
        const arr = [1, 2, 3, { nested: true }];
        storage.setItem('array', arr);

        const retrieved = storage.getItem<typeof arr>('array');
        assert.deepEqual(retrieved, arr);
        assert.ok(Object.isFrozen(retrieved));
      });
    });

    module('cross-tab communication', function () {
      test('responds to storage events for prefixed keys', function (assert) {
        const otherStorage = new TrackedStorage(windowStorage);

        // Simulate another tab changing a value
        windowStorage.setItem(
          `${DEFAULT_PREFIX}:test`,
          JSON.stringify('from_other_tab'),
        );
        window.dispatchEvent(
          new StorageEvent('storage', {
            key: `${DEFAULT_PREFIX}:test`,
            oldValue: null,
            newValue: JSON.stringify('from_other_tab'),
            storageArea: windowStorage,
          }),
        );

        assert.equal(otherStorage.getItem('test'), 'from_other_tab');
      });

      test('ignores storage events for non-prefixed keys', function (assert) {
        storage.setItem('test', 'original');

        // Simulate event for non-prefixed key
        window.dispatchEvent(
          new StorageEvent('storage', {
            key: 'non_prefixed_key',
            oldValue: null,
            newValue: JSON.stringify('should_be_ignored'),
            storageArea: windowStorage,
          }),
        );

        assert.equal(
          storage.getItem('test'),
          'original',
          'original value unchanged',
        );
        assert.equal(
          storage.getItem('non_prefixed_key'),
          null,
          'non-prefixed key not added',
        );
      });

      test('ignores storage events for different storage area', function (assert) {
        const otherStorageArea =
          name === 'localStorage' ? window.sessionStorage : window.localStorage;

        storage.setItem('test', 'original');

        // Simulate event for different storage area
        window.dispatchEvent(
          new StorageEvent('storage', {
            key: `${DEFAULT_PREFIX}:test`,
            oldValue: null,
            newValue: JSON.stringify('should_be_ignored'),
            storageArea: otherStorageArea,
          }),
        );

        assert.equal(storage.getItem('test'), 'original', 'value unchanged');
      });

      test('handles storage event with null key', function (assert) {
        assert.expect(0);

        // Simulate clear event (key is null when storage.clear() is called)
        window.dispatchEvent(
          new StorageEvent('storage', {
            key: null,
            oldValue: null,
            newValue: null,
            storageArea: windowStorage,
          }),
        );

        // Should not throw
      });
    });
  });
});
