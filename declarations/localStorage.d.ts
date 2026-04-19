import type { ElementDescriptor } from '@ember/-internals/metal';
declare const clearCache: () => void, initializeKey: (key: string) => void;
export default function localStorageDecoratorFactory(...args: ElementDescriptor): void;
export default function localStorageDecoratorFactory(): (target: object, key: string) => void;
export default function localStorageDecoratorFactory(customKey: string): (target: object, key: string) => void;
export { clearCache as clearLocalStorageCache, initializeKey as initializeLocalStorageKey, };
//# sourceMappingURL=localStorage.d.ts.map