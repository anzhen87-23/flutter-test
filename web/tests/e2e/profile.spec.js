// @ts-check
const { test, expect } = require('@playwright/test');

async function setupLogin(page) {
    await page.evaluate(() => {
        localStorage.setItem('token', 'test-token');
        localStorage.setItem('user', JSON.stringify({
            id: 1, username: 'testuser', nickname: '测试用户', phone: '138****8000'
        }));
    });
}

test.describe('文件夹页面 E2E', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('/');
        await page.evaluate(() => localStorage.clear());
        await setupLogin(page);
        await page.goto('/#/folders');
    });

    test('文件夹页面显示标题和新建按钮', async ({ page }) => {
        await expect(page.locator('h2')).toContainText('文件夹');
        await expect(page.locator('#btn-new-folder')).toBeVisible();
    });

    test('文件夹列表容器存在', async ({ page }) => {
        await expect(page.locator('#folders-list')).toBeVisible();
    });
});

test.describe('个人中心页面 E2E', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('/');
        await page.evaluate(() => localStorage.clear());
        await setupLogin(page);
        await page.goto('/#/profile');
    });

    test('个人中心页面元素完整', async ({ page }) => {
        await expect(page.locator('.profile-avatar')).toBeVisible();
        await expect(page.locator('.profile-menu')).toBeVisible();
    });

    test('菜单项存在', async ({ page }) => {
        await expect(page.locator('[data-action="nickname"]')).toBeVisible();
        await expect(page.locator('[data-action="birthday"]')).toBeVisible();
        await expect(page.locator('[data-action="phone"]')).toBeVisible();
        await expect(page.locator('[data-action="email"]')).toBeVisible();
        await expect(page.locator('[data-action="password"]')).toBeVisible();
        await expect(page.locator('[data-action="avatar"]')).toBeVisible();
    });

    test('退出按钮存在', async ({ page }) => {
        await expect(page.locator('#btn-logout-profile')).toBeVisible();
    });

    test('退出登录跳转到登录页', async ({ page }) => {
        // 处理 confirm 弹窗
        page.on('dialog', dialog => dialog.accept());
        await page.click('#btn-logout-profile');

        // 等待页面跳转
        await page.waitForTimeout(1000);
        await expect(page).toHaveURL(/\/#\/login/);
    });
});
