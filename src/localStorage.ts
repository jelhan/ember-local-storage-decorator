import type { ElementDescriptor } from '@ember/-internals/metal';
import { createStorageManager } from './storage/manager.ts';

const { decoratorFactory, clearCache, initializeKey } = createStorageManager(
  window.localStorage,
);

// Keep the original decorator overloads so TS consumers keep the same typing
export default function localStorageDecoratorFactory(
  ...args: ElementDescriptor
): void;
export default function localStorageDecoratorFactory(): (
  target: object,
  key: string,
) => void;
export default function localStorageDecoratorFactory(
  customKey: string,
): (target: object, key: string) => void;
export default function localStorageDecoratorFactory(
  ...args: unknown[]
): unknown {
  return decoratorFactory(...args);
}

export {
  clearCache as clearLocalStorageCache,
  initializeKey as initializeLocalStorageKey,
};
