import type { StorageManager, StorageOptions } from './storage/manager.ts';
import { createStorageManager } from './storage/manager.ts';

export interface LocalStorageDecorator {
  localStorage: StorageManager['decoratorFactory'];
  clearLocalStorageCache: StorageManager['clearCache'];
  initializeLocalStorageKey: StorageManager['initializeKey'];
}

export function createLocalStorageDecorator(
  options?: StorageOptions,
): LocalStorageDecorator {
  const { decoratorFactory, clearCache, initializeKey } = createStorageManager(
    window.localStorage,
    options,
  );

  return {
    localStorage: decoratorFactory,
    clearLocalStorageCache: clearCache,
    initializeLocalStorageKey: initializeKey,
  };
}

const { decoratorFactory, clearCache, initializeKey } = createStorageManager(
  window.localStorage,
);

export default decoratorFactory;
export {
  clearCache as clearLocalStorageCache,
  initializeKey as initializeLocalStorageKey,
};
