import type { ElementDescriptor } from '@ember/-internals/metal';
import { createStorageManager } from './manager.ts';

const { decoratorFactory, clearCache, initializeKey } = createStorageManager(
  window.sessionStorage,
);

export function sessionStorage(...args: ElementDescriptor): void;
export function sessionStorage(): (target: object, key: string) => void;
export function sessionStorage(
  customKey: string,
): (target: object, key: string) => void;
export function sessionStorage(...args: unknown[]): unknown {
  return decoratorFactory(...args);
}

export {
  clearCache as clearSessionStorageCache,
  initializeKey as initializeSessionStorageKey,
};
