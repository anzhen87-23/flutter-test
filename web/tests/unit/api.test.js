/**
 * API 客户端模块单元测试
 */

import { jest } from '@jest/globals';
import {
    getToken, setToken, clearToken,
    getCurrentUser, saveUser, isLoggedIn
} from '../../src/js/modules/api.js';

// Mock localStorage
const localStorageMock = (() => {
    let store = {};
    return {
        getItem: jest.fn(key => store[key] || null),
        setItem: jest.fn((key, value) => { store[key] = String(value); }),
        removeItem: jest.fn(key => { delete store[key]; }),
        clear: jest.fn(() => { store = {}; }),
    };
})();

Object.defineProperty(global, 'localStorage', { value: localStorageMock });

beforeEach(() => {
    localStorageMock.clear();
    jest.clearAllMocks();
});

describe('Token 管理', () => {
    test('setToken 保存token到localStorage', () => {
        setToken('test-token-123');
        expect(localStorageMock.setItem).toHaveBeenCalledWith('token', 'test-token-123');
    });

    test('getToken 从localStorage读取token', () => {
        localStorageMock.getItem.mockReturnValueOnce('test-token-123');
        expect(getToken()).toBe('test-token-123');
    });

    test('getToken 无token时返回null', () => {
        localStorageMock.getItem.mockReturnValueOnce(null);
        expect(getToken()).toBeNull();
    });

    test('clearToken 清除token和用户信息', () => {
        clearToken();
        expect(localStorageMock.removeItem).toHaveBeenCalledWith('token');
        expect(localStorageMock.removeItem).toHaveBeenCalledWith('user');
    });
});

describe('用户信息管理', () => {
    test('saveUser 保存用户信息JSON', () => {
        const user = { id: 1, nickname: 'TestUser', phone: '138****8000' };
        saveUser(user);
        expect(localStorageMock.setItem).toHaveBeenCalledWith('user', JSON.stringify(user));
    });

    test('getCurrentUser 读取并解析用户信息', () => {
        const user = { id: 1, nickname: 'TestUser' };
        localStorageMock.getItem.mockReturnValueOnce(JSON.stringify(user));
        expect(getCurrentUser()).toEqual(user);
    });

    test('getCurrentUser 无数据返回null', () => {
        localStorageMock.getItem.mockReturnValueOnce(null);
        expect(getCurrentUser()).toBeNull();
    });
});

describe('isLoggedIn', () => {
    test('有token时返回true', () => {
        localStorageMock.getItem.mockReturnValueOnce('test-token');
        expect(isLoggedIn()).toBe(true);
    });

    test('无token时返回false', () => {
        localStorageMock.getItem.mockReturnValueOnce(null);
        expect(isLoggedIn()).toBe(false);
    });
});
