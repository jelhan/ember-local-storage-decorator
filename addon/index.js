import { TrackedMap } from 'tracked-maps-and-sets';

const managedKeys = new Set();
const localStorageCache = new TrackedMap();

// like JSON.parse() but all returned objects are frozen
function jsonParseAndFreeze(json) {
  return JSON.parse(json, (key, value) =>
    typeof value === 'object' ? Object.freeze(value) : value
  );
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

export default function localStorageDecoratorFactory(...args) {
  const isDirectDecoratorInvocation = isElementDescriptor(...args);
  const customLocalStorageKey = isDirectDecoratorInvocation
    ? undefined
    : args[0];

  function localStorageDecorator(target, key, descriptor) {
    const localStorageKey = customLocalStorageKey ?? key;

    initalizeLocalStorageKey(localStorageKey);

    // register getter and setter
    return {
      get() {
        return (
          localStorageCache.get(localStorageKey) ??
          (descriptor.initializer
            ? descriptor.initializer.call(target)
            : undefined)
        );
      },
      set(value) {
        const json = JSON.stringify(value);

        // Update local storage cache. It must include a froozen copy the
        // the value to prevent leaking state between different consumers.
        localStorageCache.set(localStorageKey, jsonParseAndFreeze(json));

        // Update local storage.
        window.localStorage.setItem(localStorageKey, json);
      },
    };
  }

  return isDirectDecoratorInvocation
    ? localStorageDecorator(...args)
    : localStorageDecorator;
}

export function clearLocalStorageCache() {
  managedKeys.clear();
  localStorageCache.clear();
}

export function initalizeLocalStorageKey(key) {
  // Check if key is already managed. If it is not managed yet, initialize it
  // in localStorageCache with the current value in local storage.
  // Need to use a separate, not tracked data store to do this check
  // because a tracked value (`localStorageCache`) must not be read
  // before it is set.
  if (!managedKeys.has(key)) {
    managedKeys.add(key);
    localStorageCache.set(
      key,
      jsonParseAndFreeze(window.localStorage.getItem(key))
    );
  }
}

// This will detect if the function arguments match the legacy decorator pattern
//
// Borrowed from the Ember Data source code:
// https://github.com/emberjs/data/blob/22a8f20e2f11ed82c85160944e976073dc530d8b/packages/model/addon/-private/util.ts#L5
function isElementDescriptor(...args) {
  let [maybeTarget, maybeKey, maybeDescriptor] = args;

  return (
    // Ensure we have the right number of args
    args.length === 3 &&
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
