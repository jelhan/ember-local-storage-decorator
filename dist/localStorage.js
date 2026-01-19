import { createStorageManager } from './storage/manager.js';

const {
  decoratorFactory,
  clearCache,
  initializeKey
} = createStorageManager(window.localStorage);

// Keep the original decorator overloads so TS consumers keep the same typing

function localStorageDecoratorFactory(...args) {
  return decoratorFactory(...args);
}

export { clearCache as clearLocalStorageCache, localStorageDecoratorFactory as default, initializeKey as initializeLocalStorageKey };
//# sourceMappingURL=localStorage.js.map
