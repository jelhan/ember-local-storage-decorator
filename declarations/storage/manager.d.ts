export type StorageManager = {
    decoratorFactory: (...args: unknown[]) => unknown;
    clearCache: () => void;
    initializeKey: (key: string) => void;
};
export declare function createStorageManager(storage: Storage): StorageManager;
//# sourceMappingURL=manager.d.ts.map