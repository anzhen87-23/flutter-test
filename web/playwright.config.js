// @ts-check
const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
    testDir: './e2e',
    fullyParallel: true,
    forbidOnly: !!process.env.CI,
    retries: process.env.CI ? 2 : 0,
    workers: process.env.CI ? 1 : undefined,
    reporter: 'html',

    use: {
        baseURL: 'http://localhost:3000',
        trace: 'on-first-retry',
        screenshot: 'only-on-failure',
    },

    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
        },
    ],

    webServer: [
        {
            command: 'cd ../backend && go run main.go',
            url: 'http://localhost:8080/health',
            reuseExistingServer: !process.env.CI,
            timeout: 30000,
        },
        {
            command: 'npx http-server src -p 3000 -c-1',
            url: 'http://localhost:3000',
            reuseExistingServer: !process.env.CI,
            timeout: 15000,
        },
    ],
});
