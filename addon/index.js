import { TrackedMap } from 'tracked-maps-and-sets';

const localStorageCache = new TrackedMap();

export default function localStorageDecorator(customLocalStorageKey) {
  return function (target, key, descriptor) {
    const localStorageKey = customLocalStorageKey ?? key;

    if (!localStorageCache.has(localStorageKey)) {
      localStorageCache.set(
        localStorageKey,
        JSON.parse(window.localStorage.getItem(localStorageKey))
      );
    }

    // register event lister to update local state on local storage changes
    window.addEventListener('storage', function ({ key, newValue }) {
      // skip changes to other keys
      if (key !== localStorageKey) {
        return;
      }

      // skip if setting to same value
      if (localStorageCache.get(localStorageKey) === newValue) {
        return;
      }

      localStorageCache.set(localStorageKey, JSON.parse(newValue));
    });

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
  localStorageCache.clear();
}
