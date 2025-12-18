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

export const DEFAULT_PREFIX = '__tracked_storage__';

// Module-level shared caches and managed keys, keyed by storage+prefix
const sharedCaches = new Map<
  Storage,
  Map<string, TrackedMap<string, unknown>>
>();

// Setup storage event listener once at module level
// For localStorage: syncs changes across tabs
// For sessionStorage: syncs changes across iframes within the same tab
window.addEventListener('storage', (event: StorageEvent) => {
  if (!event.key || !event.storageArea) {
    return;
  }

  // Extract the prefix from the event key (e.g., '__tracked_storage__:foo' -> '__tracked_storage__')
  const colonIndex = event.key.indexOf(':');
  if (colonIndex === -1) {
    return; // Not a prefixed key
  }
  const prefix = event.key.slice(0, colonIndex);

  // Check if we have a cache for this prefix
  const cache = sharedCaches.get(event.storageArea)?.get(prefix);

  if (!cache) {
    return; // No cache exists for this prefix
  }

  const newValue = jsonParseAndFreeze(event.newValue);

  // Track or untrack key based on whether it was added or removed
  if (newValue !== null) {
    cache.set(event.key, newValue);
  } else {
    cache.delete(event.key);
  }
});

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
export class TrackedStorage {
  #prefix: string;
  #storage: Storage;
  #cache: TrackedMap<string, unknown>;

  constructor(storage: Storage, prefix?: string) {
    this.#storage = storage;
    this.#prefix = prefix ?? DEFAULT_PREFIX;
    const existingCaches = sharedCaches.get(this.#storage);
    const cacheWithPrefixExists =
      existingCaches && existingCaches.has(this.#prefix);

    if (!cacheWithPrefixExists) {
      const cache = new TrackedMap<string, unknown>(new Map());

      sharedCaches.set(
        this.#storage,
        new Map<string, TrackedMap<string, unknown>>(),
      );

      sharedCaches.get(this.#storage)!.set(this.#prefix, cache);
    }

    this.#cache = sharedCaches.get(this.#storage)!.get(this.#prefix)!;
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

    // Check if the key is already in our cache
    if (this.#cache.has(prefixedKey)) {
      return this.#cache.get(prefixedKey) as T | null;
    }

    const rawValue = this.#storage.getItem(prefixedKey);
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
    for (const key of this.#cache.keys()) {
      this.#storage.removeItem(key);
    }
    this.#cache.clear();
  };

  /**
   * Get the key at the specified index (unprefixed).
   * Only returns keys that match our prefix.
   */
  key = (index: number): string | null => {
    if (index < 0 || index >= this.#cache.size) {
      return null;
    }

    const key = Array.from(this.#cache.keys())[index];
    return key ? this.#stripPrefix(key) : null;
  };

  /**
   * Get the number of items in storage that match our prefix.
   * Accesses the TrackedMap to ensure reactivity.
   */
  get length(): number {
    return this.#cache.size;
  }

  /**
   * Clear the internal cache. Useful for tests.
   */
  clearCache = (): void => {
    this.#cache.clear();
  };
}
