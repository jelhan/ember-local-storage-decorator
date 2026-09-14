import type {
  DecoratorPropertyDescriptor,
  ElementDescriptor,
} from '@ember/-internals/metal';
import { TrackedMap } from 'tracked-built-ins';

// like JSON.parse() but all returned objects are frozen
function jsonParseAndFreeze(json: string | null | undefined): unknown {
  if (!json) {
    return undefined;
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

// This will detect if the function arguments match the legacy decorator pattern
function isElementDescriptor(...args: unknown[]): boolean {
  const [maybeTarget, maybeKey, maybeDescriptor] = args;

  return (
    (args.length === 2 || args.length === 3) &&
    (typeof maybeTarget === 'function' ||
      (typeof maybeTarget === 'object' && maybeTarget !== null)) &&
    typeof maybeKey === 'string' &&
    ((typeof maybeDescriptor === 'object' &&
      maybeDescriptor !== null &&
      'enumerable' in maybeDescriptor &&
      'configurable' in maybeDescriptor) ||
      maybeDescriptor === undefined)
  );
}

function storageKeyFor(key: string, prefix: string = ''): string {
  return `${prefix}${key}`;
}

// Keep the original decorator overloads so TS consumers keep the same typing
export interface StorageDecoratorFactory {
  (...args: ElementDescriptor): void;
  (): (target: object, key: string) => void;
  (customKey: string): (target: object, key: string) => void;
}

export type StorageManager = {
  decoratorFactory: StorageDecoratorFactory;
  clearCache: () => void;
  initializeKey: (key: string) => void;
};

export interface StorageOptions {
  /**
   * Added verbatim to the beginning of every storage key.
   * Include any desired separator, for example `"my-app:"`.
   */
  prefix?: string;
}

export function createStorageManager(
  storage: Storage,
  options: StorageOptions = {},
): StorageManager {
  const managedKeys = new Set<string>();
  const cache = new TrackedMap<string, unknown>(new Map());

  const keyPrefix = options.prefix ?? '';

  // register event listener to update local state on storage changes
  // StorageEvent is only fired for changes to localStorage across documents,
  // but it's safe to register the listener for both storage types and
  // ignore irrelevant events.
  window.addEventListener(
    'storage',
    function ({ key, newValue, storageArea }: StorageEvent) {
      if (!key) {
        return;
      }

      const storageKey = storageKeyFor(key, keyPrefix);

      // skip changes to other keys
      if (!managedKeys.has(storageKey)) {
        return;
      }

      // ensure this event is for the storage area we manage
      // storageArea can be null in test environments, so we allow it through
      if (storageArea !== null && storageArea !== storage) {
        return;
      }

      // skip if setting to same value
      if (cache.get(storageKey) === newValue) {
        return;
      }

      cache.set(storageKey, jsonParseAndFreeze(newValue));
    },
  );

  function initializeKey(key: string) {
    const storageKey = storageKeyFor(key, keyPrefix);
    if (!managedKeys.has(storageKey)) {
      managedKeys.add(storageKey);
      cache.set(storageKey, jsonParseAndFreeze(storage.getItem(storageKey)));
    }
  }

  function clearCache() {
    managedKeys.clear();
    cache.clear();
  }

  // Keep the original decorator overloads so TS consumers keep the same typing
  function decoratorFactory(...args: ElementDescriptor): void;
  function decoratorFactory(): (target: object, key: string) => void;
  function decoratorFactory(
    customKey: string,
  ): (target: object, key: string) => void;
  function decoratorFactory(...args: unknown[]): unknown {
    const isDirectDecoratorInvocation = isElementDescriptor(...args);
    const customKey: string | undefined = isDirectDecoratorInvocation
      ? undefined
      : (args[0] as string | undefined);

    function storageDecorator(
      target: object,
      key: string,
      descriptor?: DecoratorPropertyDescriptor,
    ): DecoratorPropertyDescriptor {
      const initialKey = customKey ?? key;

      initializeKey(initialKey);

      const storageKey = storageKeyFor(initialKey, keyPrefix);

      return {
        enumerable: true,
        configurable: true,
        get() {
          const cachedValue = cache.get(storageKey);
          if (cachedValue !== undefined) {
            return cachedValue;
          }

          if (descriptor?.initializer) {
            return (descriptor.initializer as () => unknown).call(target);
          }

          return undefined;
        },
        set(value: unknown) {
          const json = JSON.stringify(value);

          // Update cache with a frozen copy of the value
          cache.set(storageKey, jsonParseAndFreeze(json));

          // Update the actual storage area
          storage.setItem(storageKey, json);
        },
      };
    }

    return isDirectDecoratorInvocation
      ? storageDecorator(...(args as ElementDescriptor))
      : storageDecorator;
  }

  return {
    decoratorFactory,
    clearCache,
    initializeKey,
  };
}
