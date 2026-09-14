import type { StorageManager, StorageOptions } from './storage/manager.ts';
import { createStorageManager } from './storage/manager.ts';

interface SessionStorageDecorator {
  sessionStorage: StorageManager['decoratorFactory'];
  clearSessionStorageCache: StorageManager['clearCache'];
  initializeSessionStorageKey: StorageManager['initializeKey'];
}

export function createSessionStorageDecorator(
  options?: StorageOptions,
): SessionStorageDecorator {
  const { decoratorFactory, clearCache, initializeKey } = createStorageManager(
    window.sessionStorage,
    options,
  );

  return {
    sessionStorage: decoratorFactory,
    clearSessionStorageCache: clearCache,
    initializeSessionStorageKey: initializeKey,
  };
}

const { decoratorFactory, clearCache, initializeKey } = createStorageManager(
  window.sessionStorage,
);

export default decoratorFactory;
export {
  clearCache as clearSessionStorageCache,
  initializeKey as initializeSessionStorageKey,
};
