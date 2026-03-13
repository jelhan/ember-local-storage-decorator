import { createStorageManager } from './storage/manager.js';

const {
  decoratorFactory,
  clearCache,
  initializeKey
} = createStorageManager(window.sessionStorage);

// Mirror the same overloads as the localStorage decorator so the interface
// is identical for consumers.

function sessionStorageDecoratorFactory(...args) {
  return decoratorFactory(...args);
}

export { clearCache as clearSessionStorageCache, sessionStorageDecoratorFactory as default, initializeKey as initializeSessionStorageKey };
//# sourceMappingURL=sessionStorage.js.map
