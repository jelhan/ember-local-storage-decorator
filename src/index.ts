import type {
  DecoratorPropertyDescriptor,
  ElementDescriptor,
} from '@ember/-internals/metal';
import { trackedMap } from '@ember/reactive/collections';

const managedKeys = new Set();
const localStorageCache = trackedMap();

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

// register event lister to update local state on local storage changes
window.addEventListener('storage', function ({ key, newValue }) {
  // skip changes to other keys
  if (!managedKeys.has(key)) {
    return;
  }

  // skip if setting to same value
  if (localStorageCache.get(key) === newValue) {
    return;
  }

  localStorageCache.set(key, jsonParseAndFreeze(newValue));
});

// Note: Type unions are intentionally omitted because the factory
// implementation uses a generic `unknown[]` overload to remain compatible
// with decorator call signatures in different runtimes.

/**
 * Bind a class property to `window.localStorage`.
 *
 * This decorator makes it easy to store JSON-serializable values in the
 * browser's `localStorage` and access them from Ember components or other
 * classes.
 *
 * Examples
 * ```js
 * import localStorage from 'ember-local-storage-decorator';
 *
 * // Use the property name as the storage key
 * export default class MyComponent {
 *   @localStorage foo; // stored under key 'foo'
 * }
 *
 * // Supply a custom key
 * export default class OtherComp {
 *   @localStorage('myKey') bar; // stored under key 'myKey'
 * }
 * ```
 *
 * Key behavior
 * - Values are saved as JSON strings in `localStorage` when you assign to the
 *   decorated property.
 * - The getter returns the parsed value. Objects and arrays are deep frozen to
 *   prevent accidental mutation — consumers will receive a frozen copy.
 * - Changes made by other instances or other browser tabs/windows are
 *   propagated via the `storage` event and reflected in the decorated property.
 *
 * Important notes for consumers
 * - Only JSON-serializable values are supported (primitives, arrays, plain
 *   objects, etc.).
 * - Do not directly mutate the objects returned by the getter — they are
 *   frozen by design. If you need a mutable copy, clone before modifying.
 * - Avoid directly writing to `window.localStorage` for keys managed by this
 *   decorator; use the decorated property instead so the internal cache stays
 *   in sync.
 *
 * Testing helpers
 * - Call `clearLocalStorageCache()` in test setup/teardown to avoid cross-test
 *   leakage of internal cache state.
 * - If you set `window.localStorage` directly in a test, call
 *   `initializeLocalStorageKey('key')` to reinitialize the decorator's cache
 *   for that key.
 *
 * Usage details
 * - When used as `@localStorage` the property name is used as the storage key.
 * - When used as `@localStorage('key')` the provided string is used as the
 *   storage key.
 *
 * @param args Either the decorator descriptor (when the decorator is applied
 *   directly by the runtime) or an optional custom key string when invoked as a
 *   factory (`@localStorage('key')`).
 * @returns A property descriptor object (`{ get, set }`) when called with a
 *   descriptor, or a decorator function when called with a custom key.
 */
// When used directly as a decorator (legacy runtime) TypeScript expects the
// decorator to return `void` (or `any`). Use `void` here so decorator-aware
// tooling (templates, tsserver plugins) accept `@localStorage` usage.
export default function localStorageDecoratorFactory(
  ...args: ElementDescriptor
): void;
// When invoked as @localStorage() or @localStorage('key'), return a decorator function
export default function localStorageDecoratorFactory(): (
  target: object,
  key: string,
) => void;
export default function localStorageDecoratorFactory(
  customKey: string,
): (target: object, key: string) => void;
export default function localStorageDecoratorFactory(
  ...args: unknown[]
): unknown {
  const isDirectDecoratorInvocation = isElementDescriptor(...args);
  const customLocalStorageKey: string | undefined = isDirectDecoratorInvocation
    ? undefined
    : (args[0] as string | undefined);

  function localStorageDecorator(
    target: object,
    key: string,
    descriptor?: DecoratorPropertyDescriptor,
  ): DecoratorPropertyDescriptor {
    const localStorageKey = customLocalStorageKey ?? key;

    initializeLocalStorageKey(localStorageKey);

    return {
      enumerable: true,
      configurable: true,
      get() {
        const cachedValue = localStorageCache.get(localStorageKey);
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

        // Update local storage cache. It must include a frozen copy of
        // the value to prevent leaking state between different consumers.
        localStorageCache.set(localStorageKey, jsonParseAndFreeze(json));

        // Update local storage.
        window.localStorage.setItem(localStorageKey, json);
      },
    };
  }

  return isDirectDecoratorInvocation
    ? localStorageDecorator(...(args as ElementDescriptor))
    : localStorageDecorator;
}

export function clearLocalStorageCache() {
  managedKeys.clear();
  localStorageCache.clear();
}

export function initializeLocalStorageKey(key: string) {
  // Check if key is already managed. If it is not managed yet, initialize it
  // in localStorageCache with the current value in local storage.
  // Need to use a separate, not tracked data store to do this check
  // because a tracked value (`localStorageCache`) must not be read
  // before it is set.
  if (!managedKeys.has(key)) {
    managedKeys.add(key);
    localStorageCache.set(
      key,
      jsonParseAndFreeze(window.localStorage.getItem(key)),
    );
  }
}

// This will detect if the function arguments match the legacy decorator pattern
//
// Borrowed from the Ember Data source code:
// https://github.com/emberjs/data/blob/22a8f20e2f11ed82c85160944e976073dc530d8b/packages/model/addon/-private/util.ts#L5
function isElementDescriptor(...args: unknown[]): boolean {
  const [maybeTarget, maybeKey, maybeDescriptor] = args;

  return (
    // Ensure we have the right number of args (legacy decorators may be
    // applied with 2 or 3 arguments depending on runtime)
    (args.length === 2 || args.length === 3) &&
    // Make sure the target is a class or object (prototype)
    (typeof maybeTarget === 'function' ||
      (typeof maybeTarget === 'object' && maybeTarget !== null)) &&
    // Make sure the key is a string
    typeof maybeKey === 'string' &&
    // Make sure the descriptor is the right shape
    ((typeof maybeDescriptor === 'object' &&
      maybeDescriptor !== null &&
      'enumerable' in maybeDescriptor &&
      'configurable' in maybeDescriptor) ||
      // TS compatibility
      maybeDescriptor === undefined)
  );
}
