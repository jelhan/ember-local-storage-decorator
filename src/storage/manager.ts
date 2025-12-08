import type {
  DecoratorPropertyDescriptor,
  ElementDescriptor,
} from '@ember/-internals/metal';
import { TrackedStorage } from '../TrackedStorage.ts';

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
  // Use TrackedStorage as the underlying primitive
  const trackedStorage = new TrackedStorage(storage);

  function initializeKey(key: string) {
    // TrackedStorage automatically initializes keys on access, but we can
    // preemptively access it to ensure it's in the cache
    trackedStorage.getItem(key);
  }

  function clearCache() {
    trackedStorage.clearCache();
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
          const value = trackedStorage.getItem(storageKey);

          // If value exists in storage, return it
          if (value !== null) {
            return value;
          }

          // If no value in storage, try descriptor initializer
          if (descriptor?.initializer) {
            return (descriptor.initializer as () => unknown).call(target);
          }

          return undefined;
        },
        set(value: unknown) {
          trackedStorage.setItem(storageKey, value);
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
