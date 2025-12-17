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

export type StorageManager = {
  decoratorFactory: (...args: unknown[]) => unknown;
  clearCache: () => void;
  initializeKey: (key: string) => void;
};

export function createStorageManager(storage: Storage): StorageManager {
  const managedKeys = new Set<string>();
  const cache = new TrackedMap<string, unknown>(new Map());

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

      // skip changes to other keys
      if (!managedKeys.has(key)) {
        return;
      }

      // ensure this event is for the storage area we manage
      // storageArea can be null in test environments, so we allow it through
      if (storageArea !== null && storageArea !== storage) {
        return;
      }

      // skip if setting to same value
      if (cache.get(key) === newValue) {
        return;
      }

      cache.set(key, jsonParseAndFreeze(newValue));
    },
  );

  function initializeKey(key: string) {
    if (!managedKeys.has(key)) {
      managedKeys.add(key);
      cache.set(key, jsonParseAndFreeze(storage.getItem(key)));
    }
  }

  function clearCache() {
    managedKeys.clear();
    cache.clear();
  }

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
      const storageKey = customKey ?? key;

      initializeKey(storageKey);

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
