// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('认证流程 E2E', () => {
    test.beforeEach(async ({ page }) => {
        // 清除 localStorage
        await page.goto('/');
        await page.evaluate(() => localStorage.clear());
    });

    test('未登录时跳转到登录页', async ({ page }) => {
        await page.goto('/');
        await expect(page).toHaveURL(/\/#\/login/);
        await expect(page.locator('h2')).toContainText('登录');
    });

    test('登录页面元素完整', async ({ page }) => {
        await page.goto('/#/login');

        await expect(page.locator('#login-account')).toBeVisible();
        await expect(page.locator('#login-password')).toBeVisible();
        await expect(page.locator('#login-btn')).toBeVisible();
        await expect(page.locator('a[href="#/register"]')).toBeVisible();
        await expect(page.locator('a[href="#/reset-password"]')).toBeVisible();
    });

    test('密码只允许输入数字', async ({ page }) => {
        await page.goto('/#/login');

        await page.fill('#login-password', 'abc123def');
        const value = await page.inputValue('#login-password');
        expect(value).toBe('123');
    });

    test('密码最多6位', async ({ page }) => {
        await page.goto('/#/login');

        await page.fill('#login-password', '123456789');
        const value = await page.inputValue('#login-password');
        expect(value).toBe('123456');
    });

    test('空密码提交显示错误提示', async ({ page }) => {
        await page.goto('/#/login');

        await page.fill('#login-account', '13800008000');
        await page.click('#login-btn');

        // Toast 应该显示
        await expect(page.locator('.toast')).toBeVisible({ timeout: 3000 });
    });

    test('注册页面切换标签', async ({ page }) => {
        await page.goto('/#/register');

        // 默认显示手机号注册
        await expect(page.locator('#register-phone-form')).toBeVisible();
        await expect(page.locator('#register-email-form')).not.toBeVisible();

        // 切换到邮箱注册
        await page.click('[data-tab="email"]');
        await expect(page.locator('#register-email-form')).toBeVisible();
        await expect(page.locator('#register-phone-form')).not.toBeVisible();

        // 切回手机号
        await page.click('[data-tab="phone"]');
        await expect(page.locator('#register-phone-form')).toBeVisible();
    });

    test('注册页面手机号只允许数字', async ({ page }) => {
        await page.goto('/#/register');

        await page.fill('#reg-phone', 'abc13800008000def');
        const value = await page.inputValue('#reg-phone');
        expect(value).toBe('13800008000');
    });

    test('重置密码页面元素完整', async ({ page }) => {
        await page.goto('/#/reset-password');

        await expect(page.locator('#reset-account')).toBeVisible();
        await expect(page.locator('#reset-code')).toBeVisible();
        await expect(page.locator('#reset-password')).toBeVisible();
        await expect(page.locator('#reset-password-confirm')).toBeVisible();
        await expect(page.locator('#send-reset-code')).toBeVisible();
    });

    test('重置密码两次密码不一致', async ({ page }) => {
        await page.goto('/#/reset-password');

        await page.fill('#reset-account', '13800008000');
        await page.fill('#reset-code', '123456');
        await page.fill('#reset-password', '123456');
        await page.fill('#reset-password-confirm', '654321');
        await page.click('button[type="submit"]');

        // 应显示不一致错误
        await expect(page.locator('.toast')).toBeVisible({ timeout: 3000 });
        await expect(page.locator('.toast')).toContainText('不一致');
    });
});

test.describe('笔记页面 E2E', () => {
    test('未登录访问笔记页跳转到登录', async ({ page }) => {
        await page.goto('/');
        await page.evaluate(() => localStorage.clear());
        await page.goto('/#/notes');

        await expect(page).toHaveURL(/\/#\/login/);
    });
});
