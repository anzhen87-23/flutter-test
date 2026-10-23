// @ts-check
const { test, expect } = require('@playwright/test');

// 辅助：设置登录状态
async function setupLogin(page) {
    await page.evaluate(() => {
        localStorage.setItem('token', 'test-token');
        localStorage.setItem('user', JSON.stringify({
            id: 1,
            username: 'testuser',
            nickname: '测试用户',
            phone: '138****8000'
        }));
    });
}

test.describe('笔记列表页 E2E', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('/');
        await page.evaluate(() => localStorage.clear());
        await setupLogin(page);
        await page.goto('/#/notes');
    });

    test('笔记页面显示标题和新建按钮', async ({ page }) => {
        await expect(page.locator('h2')).toContainText('我的笔记');
        await expect(page.locator('#btn-new-note')).toBeVisible();
    });

    test('文件夹筛选器存在', async ({ page }) => {
        await expect(page.locator('#folder-filter')).toBeVisible();
    });

    test('点击新建笔记跳转到编辑器', async ({ page }) => {
        await page.click('#btn-new-note');
        await expect(page.locator('.editor-title')).toBeVisible();
        await expect(page.locator('#note-content')).toBeVisible();
    });
});

test.describe('笔记编辑器 E2E', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('/');
        await page.evaluate(() => localStorage.clear());
        await setupLogin(page);
        await page.goto('/#/note/new');
    });

    test('编辑器页面元素完整', async ({ page }) => {
        await expect(page.locator('.editor-title')).toBeVisible();
        await expect(page.locator('#note-content')).toBeVisible();
        await expect(page.locator('#note-folder')).toBeVisible();
        await expect(page.locator('#btn-save')).toBeVisible();
        await expect(page.locator('#btn-cancel')).toBeVisible();
        await expect(page.locator('#btn-back')).toBeVisible();
    });

    test('标题最大长度200', async ({ page }) => {
        const longTitle = 'a'.repeat(250);
        await page.fill('.editor-title', longTitle);
        const value = await page.inputValue('.editor-title');
        expect(value.length).toBeLessThanOrEqual(200);
    });

    test('空标题保存显示错误', async ({ page }) => {
        await page.click('#btn-save');
        await expect(page.locator('.toast')).toBeVisible({ timeout: 3000 });
    });

    test('返回按钮回到笔记列表', async ({ page }) => {
        await page.click('#btn-back');
        await expect(page.locator('h2')).toContainText('我的笔记');
    });

    test('取消按钮回到笔记列表', async ({ page }) => {
        await page.click('#btn-cancel');
        await expect(page.locator('h2')).toContainText('我的笔记');
    });
});
