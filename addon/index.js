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

export default function localStorageDecorator(customLocalStorageKey) {
  return function (target, key, descriptor) {
    const localStorageKey = customLocalStorageKey ?? key;

    // Check if key is already managed. If it is not managed yet, initialize it
    // in localStorageCache with the current value in local storage.
    // Need to use a separate, not tracked data store to do this check
    // because a tracked value (`localStorageCache`) must not be read
    // before it is set.
    if (!managedKeys.has(localStorageKey)) {
      managedKeys.add(localStorageKey);
      localStorageCache.set(
        localStorageKey,
        jsonParseAndFreeze(window.localStorage.getItem(localStorageKey))
      );
    }

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
  };
}

export function clearLocalStorageCache() {
  managedKeys.clear();
  localStorageCache.clear();
}
