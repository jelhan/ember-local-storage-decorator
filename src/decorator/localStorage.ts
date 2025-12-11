import type { ElementDescriptor } from '@ember/-internals/metal';
import { createStorageManager } from './manager.ts';

const { decoratorFactory, clearCache, initializeKey } = createStorageManager(
  window.localStorage,
);

export function localStorage(...args: ElementDescriptor): void;
export function localStorage(): (target: object, key: string) => void;
export function localStorage(
  customKey: string,
): (target: object, key: string) => void;
export function localStorage(...args: unknown[]): unknown {
  return decoratorFactory(...args);
}

export {
  clearCache as clearLocalStorageCache,
  initializeKey as initializeLocalStorageKey,
};
