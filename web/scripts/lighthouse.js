/**
 * Lighthouse 性能测试脚本
 * 测试各页面的性能、可访问性、SEO 等指标
 */

import lighthouse from 'lighthouse';
import { launch } from 'chrome-launcher';

const BASE_URL = 'http://localhost:3000';

const pages = [
    { name: '登录页', path: '/#/login' },
    { name: '注册页', path: '/#/register' },
    { name: '重置密码', path: '/#/reset-password' },
];

async function runLighthouse(url) {
    const chrome = await launch({
        chromeFlags: ['--headless', '--no-sandbox', '--disable-gpu'],
    });

    try {
        const result = await lighthouse(url, {
            port: chrome.port,
            output: 'json',
            onlyCategories: ['performance', 'accessibility', 'best-practices', 'seo'],
        });

        return {
            url,
            performance: result.lhr.categories.performance.score * 100,
            accessibility: result.lhr.categories.accessibility.score * 100,
            bestPractices: result.lhr.categories['best-practices'].score * 100,
            seo: result.lhr.categories.seo.score * 100,
            firstContentfulPaint: result.lhr.audits['first-contentful-paint'].numericValue,
            largestContentfulPaint: result.lhr.audits['largest-contentful-paint'].numericValue,
            totalBlockingTime: result.lhr.audits['total-blocking-time'].numericValue,
            cumulativeLayoutShift: result.lhr.audits['cumulative-layout-shift'].numericValue,
        };
    } finally {
        await chrome.kill();
    }
}

async function main() {
    console.log('🔍 开始 Lighthouse 性能测试...\n');

    const results = [];

    for (const page of pages) {
        const url = `${BASE_URL}${page.path}`;
        console.log(`测试: ${page.name} (${url})`);

        try {
            const result = await runLighthouse(url);
            results.push({ name: page.name, ...result });
            console.log(`  ✅ 性能: ${result.performance} | 可访问性: ${result.accessibility}`);
        } catch (error) {
            console.error(`  ❌ 失败: ${error.message}`);
        }
    }

    // 输出汇总
    console.log('\n📊 测试结果汇总:');
    console.log('─'.repeat(80));
    console.log(`${'页面'.padEnd(12)} ${'性能'.padStart(6)} ${'可访问性'.padStart(10)} ${'最佳实践'.padStart(10)} ${'SEO'.padStart(6)} ${'FCP(ms)'.padStart(8)} ${'LCP(ms)'.padStart(8)}`);
    console.log('─'.repeat(80));

    for (const r of results) {
        console.log(
            `${r.name.padEnd(12)} ` +
            `${String(r.performance).padStart(6)} ` +
            `${String(r.accessibility).padStart(10)} ` +
            `${String(r.bestPractices).padStart(10)} ` +
            `${String(r.seo).padStart(6)} ` +
            `${String(Math.round(r.firstContentfulPaint)).padStart(8)} ` +
            `${String(Math.round(r.largestContentfulPaint)).padStart(8)}`
        );
    }
    console.log('─'.repeat(80));

    // 检查是否达标
    const threshold = 80;
    const passed = results.every(r =>
        r.performance >= threshold &&
        r.accessibility >= threshold
    );

    if (passed) {
        console.log(`\n✅ 所有页面性能指标达标 (≥${threshold}分)`);
    } else {
        console.log(`\n⚠️ 部分页面未达标 (目标≥${threshold}分)`);
        process.exit(1);
    }
}

main().catch(err => {
    console.error('Lighthouse 测试失败:', err);
    process.exit(1);
});
