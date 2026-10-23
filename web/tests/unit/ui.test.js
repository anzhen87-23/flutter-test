/**
 * UI 工具模块单元测试
 */

import { jest } from '@jest/globals';
import {
    validatePhone, validateEmail, validatePassword,
    validateCode, formatDate, escapeHtml, debounce
} from '../../src/js/modules/ui.js';

describe('validatePhone', () => {
    test('有效手机号', () => {
        expect(validatePhone('13800008000')).toBe(true);
        expect(validatePhone('13912345678')).toBe(true);
        expect(validatePhone('15800000000')).toBe(true);
        expect(validatePhone('18612345678')).toBe(true);
    });

    test('无效手机号', () => {
        expect(validatePhone('')).toBe(false);
        expect(validatePhone('12345678901')).toBe(false); // 不是1开头
        expect(validatePhone('1380000800')).toBe(false);  // 10位
        expect(validatePhone('138000080001')).toBe(false); // 12位
        expect(validatePhone('12800008000')).toBe(false); // 第二位不是3-9
        expect(validatePhone('abcdefghijk')).toBe(false);
    });
});

describe('validateEmail', () => {
    test('有效邮箱', () => {
        expect(validateEmail('test@example.com')).toBe(true);
        expect(validateEmail('user.name@domain.co')).toBe(true);
        expect(validateEmail('user+tag@gmail.com')).toBe(true);
    });

    test('无效邮箱', () => {
        expect(validateEmail('')).toBe(false);
        expect(validateEmail('notemail')).toBe(false);
        expect(validateEmail('@example.com')).toBe(false);
        expect(validateEmail('user@')).toBe(false);
        expect(validateEmail('user @example.com')).toBe(false);
    });
});

describe('validatePassword', () => {
    test('有效密码（6位数字）', () => {
        expect(validatePassword('123456')).toBe(true);
        expect(validatePassword('000000')).toBe(true);
        expect(validatePassword('999999')).toBe(true);
    });

    test('无效密码', () => {
        expect(validatePassword('')).toBe(false);
        expect(validatePassword('12345')).toBe(false);   // 5位
        expect(validatePassword('1234567')).toBe(false);  // 7位
        expect(validatePassword('abcdef')).toBe(false);   // 字母
        expect(validatePassword('12345a')).toBe(false);   // 包含字母
        expect(validatePassword('12 345')).toBe(false);   // 包含空格
    });
});

describe('validateCode', () => {
    test('有效验证码（6位数字）', () => {
        expect(validateCode('123456')).toBe(true);
        expect(validateCode('000000')).toBe(true);
    });

    test('无效验证码', () => {
        expect(validateCode('')).toBe(false);
        expect(validateCode('12345')).toBe(false);
        expect(validateCode('1234567')).toBe(false);
        expect(validateCode('abcdef')).toBe(false);
    });
});

describe('formatDate', () => {
    test('刚刚', () => {
        const now = new Date();
        expect(formatDate(now.toISOString())).toBe('刚刚');
    });

    test('几分钟前', () => {
        const date = new Date(Date.now() - 5 * 60 * 1000);
        expect(formatDate(date.toISOString())).toBe('5分钟前');
    });

    test('几小时前', () => {
        const date = new Date(Date.now() - 3 * 60 * 60 * 1000);
        expect(formatDate(date.toISOString())).toBe('3小时前');
    });

    test('几天前', () => {
        const date = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000);
        expect(formatDate(date.toISOString())).toBe('2天前');
    });

    test('空值', () => {
        expect(formatDate('')).toBe('');
        expect(formatDate(null)).toBe('');
    });
});

describe('escapeHtml', () => {
    test('转义HTML特殊字符', () => {
        expect(escapeHtml('<script>alert("xss")</script>'))
            .toBe('&lt;script&gt;alert("xss")&lt;/script&gt;');
        expect(escapeHtml('Hello & World'))
            .toBe('Hello &amp; World');
        // textContent 不转义引号（引号在文本内容中合法）
        expect(escapeHtml('"quotes"'))
            .toBe('"quotes"');
    });

    test('普通文本不变', () => {
        expect(escapeHtml('Hello World')).toBe('Hello World');
        expect(escapeHtml('你好世界')).toBe('你好世界');
    });
});

describe('debounce', () => {
    jest.useFakeTimers();

    test('防抖执行', () => {
        const fn = jest.fn();
        const debouncedFn = debounce(fn, 300);

        debouncedFn();
        debouncedFn();
        debouncedFn();

        expect(fn).not.toBeCalled();

        jest.advanceTimersByTime(300);

        expect(fn).toHaveBeenCalledTimes(1);
    });

    test('防抖延迟', () => {
        const fn = jest.fn();
        const debouncedFn = debounce(fn, 500);

        debouncedFn();
        jest.advanceTimersByTime(200);
        debouncedFn(); // 重置计时器
        jest.advanceTimersByTime(200);

        expect(fn).not.toBeCalled();

        jest.advanceTimersByTime(300);

        expect(fn).toHaveBeenCalledTimes(1);
    });
});
