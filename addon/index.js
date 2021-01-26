import { TrackedMap } from 'tracked-maps-and-sets';

const managedKeys = new Set();
const localStorageCache = new TrackedMap();

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

  localStorageCache.set(key, JSON.parse(newValue));
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
        JSON.parse(window.localStorage.getItem(localStorageKey))
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
        localStorageCache.set(localStorageKey, value);
        window.localStorage.setItem(localStorageKey, JSON.stringify(value));
      },
    };
  };
}

export function clearLocalStorageCache() {
  managedKeys.clear();
  localStorageCache.clear();
}
