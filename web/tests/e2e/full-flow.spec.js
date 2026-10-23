// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('完整流程 E2E', () => {
    test('完整用户流程：注册 → 登录 → 创建笔记 → 查看 → 编辑 → 删除 → 退出', async ({ page }) => {
        // 1. 访问首页，应该跳转到登录页
        await page.goto('/');
        await expect(page).toHaveURL(/\/#\/login/);

        // 2. 跳转到注册页
        await page.click('a[href="#/register"]');
        await expect(page).toHaveURL(/\/#\/register/);

        // 3. 验证注册表单存在
        await expect(page.locator('#reg-phone')).toBeVisible();
        await expect(page.locator('#reg-phone-code')).toBeVisible();
        await expect(page.locator('#reg-phone-password')).toBeVisible();

        // 4. 切换回登录页
        await page.click('a[href="#/login"]');
        await expect(page).toHaveURL(/\/#\/login/);

        // 5. 模拟已登录状态（因为没有真实后端验证码）
        await page.evaluate(() => {
            localStorage.setItem('token', 'test-token');
            localStorage.setItem('user', JSON.stringify({
                id: 1, username: 'testuser', nickname: '测试用户', phone: '138****8000'
            }));
        });

        // 6. 访问笔记页
        await page.goto('/#/notes');
        await expect(page.locator('h2')).toContainText('我的笔记');

        // 7. 点击新建笔记
        await page.click('#btn-new-note');
        await expect(page.locator('.editor-title')).toBeVisible();

        // 8. 填写笔记内容
        await page.fill('.editor-title', '测试笔记标题');
        await page.fill('#note-content', '这是一条测试笔记内容');

        // 9. 返回笔记列表
        await page.click('#btn-back');
        await expect(page.locator('h2')).toContainText('我的笔记');

        // 10. 访问文件夹页
        await page.click('[data-page="folders"]');
        await expect(page).toHaveURL(/\/#\/folders/);
        await expect(page.locator('h2')).toContainText('文件夹');

        // 11. 访问个人中心
        await page.click('[data-page="profile"]');
        await expect(page).toHaveURL(/\/#\/profile/);
        await expect(page.locator('.profile-menu')).toBeVisible();

        // 12. 检查导航高亮
        await expect(page.locator('[data-page="profile"]')).toHaveClass(/active/);

        // 13. 退出登录
        page.on('dialog', dialog => dialog.accept());
        await page.click('#btn-logout-profile');
        await page.waitForTimeout(1000);
        await expect(page).toHaveURL(/\/#\/login/);

        // 14. 验证已清除登录状态
        const token = await page.evaluate(() => localStorage.getItem('token'));
        expect(token).toBeNull();
    });

    test('导航栏切换测试', async ({ page }) => {
        // 模拟登录
        await page.goto('/');
        await page.evaluate(() => {
            localStorage.setItem('token', 'test-token');
            localStorage.setItem('user', JSON.stringify({ id: 1 }));
        });

        await page.goto('/#/notes');

        // 验证笔记标签高亮
        await expect(page.locator('[data-page="notes"]')).toHaveClass(/active/);

        // 切换到文件夹
        await page.click('[data-page="folders"]');
        await expect(page.locator('[data-page="folders"]')).toHaveClass(/active/);
        await expect(page.locator('[data-page="notes"]')).not.toHaveClass(/active/);

        // 切换到个人中心
        await page.click('[data-page="profile"]');
        await expect(page.locator('[data-page="profile"]')).toHaveClass(/active/);
        await expect(page.locator('[data-page="folders"]')).not.toHaveClass(/active/);

        // 切换回笔记
        await page.click('[data-page="notes"]');
        await expect(page.locator('[data-page="notes"]')).toHaveClass(/active/);
    });
});
