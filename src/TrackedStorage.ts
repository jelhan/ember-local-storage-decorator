import { TrackedMap } from 'tracked-built-ins';

// like JSON.parse() but all returned objects are frozen
function jsonParseAndFreeze(json: string | null | undefined): unknown {
  if (!json) {
    return null;
  }

  const parsed: unknown = JSON.parse(
    json,
    (_key: string, value: unknown): unknown =>
      typeof value === 'object' && value !== null
        ? Object.freeze(value)
        : value,
  );

  return parsed;
}

/**
 * A tracked wrapper around the Web Storage API (localStorage or sessionStorage).
 * All get/set operations are reactive and will trigger Ember's reactivity system.
 * Values are automatically JSON serialized/deserialized and frozen to prevent mutation.
 *
 * @example
 * ```js
 * const storage = new TrackedStorage(window.localStorage);
 *
 * storage.setItem('user', { name: 'Alice' });
 * const user = storage.getItem('user'); // { name: 'Alice' }
 *
 * storage.setItem('count', 42);
 * const count = storage.getItem('count'); // 42
 * ```
 */
export const DEFAULT_PREFIX = '__tracked_storage__';

export class TrackedStorage {
  #prefix: string;
  #storage: Storage;
  #cache = new TrackedMap<string, unknown>(new Map());
  #managedKeys = new Set<string>();

  constructor(storage: Storage, prefix?: string) {
    this.#storage = storage;
    this.#prefix = prefix ?? DEFAULT_PREFIX;

    // Initialize cache with existing storage values that match our prefix
    for (let i = 0; i < storage.length; i++) {
      const key = storage.key(i);
      if (key && key.startsWith(`${this.#prefix}:`)) {
        this.#cache.set(key, jsonParseAndFreeze(storage.getItem(key)));
        this.#managedKeys.add(key);
      }
    }

    // Listen for storage events from other tabs/windows
    window.addEventListener('storage', (event: StorageEvent) => {
      if (!event.key) {
        return;
      }

      // Ensure this event is for our storage area
      if (event.storageArea !== null && event.storageArea !== storage) {
        return;
      }

      // Only track keys we're managing
      if (!this.#managedKeys.has(event.key)) {
        return;
      }

      // Update cache
      const newValue = jsonParseAndFreeze(event.newValue);
      this.#cache.set(event.key, newValue);

      // Track or untrack key based on whether it was added or removed
      if (newValue !== null) {
        this.#managedKeys.add(event.key);
      } else {
        this.#managedKeys.delete(event.key);
      }
    });
  }

  /**
   * Build the full storage key with prefix
   */
  #buildKey = (key: string): string => {
    return `${this.#prefix}:${key}`;
  };

  /**
   * Strip the prefix from a key
   */
  #stripPrefix = (key: string): string => {
    const prefix = `${this.#prefix}:`;
    return key.startsWith(prefix) ? key.slice(prefix.length) : key;
  };

  /**
   * Get an item from storage. Returns the parsed value or null if not found.
   * Objects and arrays are deep frozen to prevent mutation.
   *
   * Note: This method accesses the cache for reactivity. Values that don't exist
   * in storage will return null without being cached to avoid tracking violations.
   */
  getItem = <T = unknown>(key: string): T | null => {
    const prefixedKey = this.#buildKey(key);

    // Check if the key is tracked in our cache
    if (this.#cache.has(prefixedKey)) {
      return this.#cache.get(prefixedKey) as T | null;
    }

    // For keys not in cache, check if they exist in storage
    // If they don't exist, return null without caching to avoid tracking violations
    const rawValue = this.#storage.getItem(prefixedKey);
    if (rawValue === null) {
      return null;
    }

    // Key exists in storage but not cache - this shouldn't normally happen
    // since we initialize the cache in constructor, but handle it gracefully
    const value = jsonParseAndFreeze(rawValue);
    this.#cache.set(prefixedKey, value);
    return value as T | null;
  };

  /**
   * Set an item in storage. Value will be JSON serialized.
   * Setting a value to undefined or null will remove it from storage.
   */
  setItem = (key: string, value: unknown): void => {
    if (value === undefined || value === null) {
      this.removeItem(key);
      return;
    }

    const prefixedKey = this.#buildKey(key);
    const json = JSON.stringify(value);

    // Update cache with frozen copy
    this.#cache.set(prefixedKey, jsonParseAndFreeze(json));

    // Track this key
    this.#managedKeys.add(prefixedKey);

    // Update storage
    this.#storage.setItem(prefixedKey, json);
  };

  /**
   * Remove an item from storage.
   */
  removeItem = (key: string): void => {
    const prefixedKey = this.#buildKey(key);
    this.#cache.delete(prefixedKey);
    this.#managedKeys.delete(prefixedKey);
    this.#storage.removeItem(prefixedKey);
  };

  /**
   * Clear all items from storage that match our prefix.
   */
  clear = (): void => {
    this.#cache.clear();

    for (const key of this.#managedKeys) {
      this.#storage.removeItem(key);
    }

    this.#managedKeys.clear();
  };

  /**
   * Get the key at the specified index (unprefixed).
   * Only returns keys that match our prefix.
   */
  key = (index: number): string | null => {
    if (index < 0 || index >= this.#managedKeys.size) {
      return null;
    }

    const key = Array.from(this.#managedKeys)[index];
    return key ? this.#stripPrefix(key) : null;
  };

  /**
   * Get the number of items in storage that match our prefix.
   */
  get length(): number {
    return this.#managedKeys.size;
  }

  /**
   * Clear the internal cache. Useful for tests.
   */
  clearCache = (): void => {
    this.#cache.clear();
  };
}
