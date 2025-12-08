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
  #storage: Storage;
  #cache: TrackedMap<string, unknown>;
  #prefix: string;

  constructor(storage: Storage, prefix?: string) {
    this.#storage = storage;
    this.#cache = new TrackedMap<string, unknown>(new Map());
    this.#prefix = prefix ?? DEFAULT_PREFIX;

    // Initialize cache with existing storage values that match our prefix
    for (let i = 0; i < storage.length; i++) {
      const key = storage.key(i);
      if (key && this.#matchesPrefix(key)) {
        this.#cache.set(key, jsonParseAndFreeze(storage.getItem(key)));
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

      // Only track keys that match our prefix
      if (!this.#matchesPrefix(event.key)) {
        return;
      }

      // Update cache
      this.#cache.set(event.key, jsonParseAndFreeze(event.newValue));
    });
  }

  /**
   * Build the full storage key with prefix
   */
  #buildKey = (key: string): string => {
    return `${this.#prefix}:${key}`;
  };

  /**
   * Check if a key matches our prefix pattern
   */
  #matchesPrefix = (key: string): boolean => {
    return key.startsWith(`${this.#prefix}:`);
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
      // Touch the cache to track this access, but don't store null
      // This ensures reactivity works when the value is later set
      this.#cache.get(prefixedKey); // This returns undefined, but tracks the access
      return null;
    }

    // Key exists in storage but not cache - this shouldn't normally happen
    // since we initialize the cache in constructor, but handle it gracefully
    const value = jsonParseAndFreeze(rawValue);
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

    // Update storage
    this.#storage.setItem(prefixedKey, json);
  };

  /**
   * Remove an item from storage.
   */
  removeItem = (key: string): void => {
    const prefixedKey = this.#buildKey(key);
    this.#cache.delete(prefixedKey);
    this.#storage.removeItem(prefixedKey);
  };

  /**
   * Clear all items from storage that match our prefix.
   */
  clear = (): void => {
    // Clear cache
    this.#cache.clear();

    // Clear only items with our prefix from storage
    const keysToRemove: string[] = [];
    for (let i = 0; i < this.#storage.length; i++) {
      const key = this.#storage.key(i);
      if (key && this.#matchesPrefix(key)) {
        keysToRemove.push(key);
      }
    }

    for (const key of keysToRemove) {
      this.#storage.removeItem(key);
    }
  };

  /**
   * Get the key at the specified index (unprefixed).
   * Only returns keys that match our prefix.
   */
  key = (index: number): string | null => {
    let count = 0;
    for (let i = 0; i < this.#storage.length; i++) {
      const key = this.#storage.key(i);
      if (key && this.#matchesPrefix(key)) {
        if (count === index) {
          return this.#stripPrefix(key);
        }
        count++;
      }
    }
    return null;
  };

  /**
   * Get the number of items in storage that match our prefix.
   */
  get length(): number {
    let count = 0;
    for (let i = 0; i < this.#storage.length; i++) {
      const key = this.#storage.key(i);
      if (key && this.#matchesPrefix(key)) {
        count++;
      }
    }
    return count;
  }

  /**
   * Clear the internal cache. Useful for tests.
   */
  clearCache = (): void => {
    this.#cache.clear();
  };
}
