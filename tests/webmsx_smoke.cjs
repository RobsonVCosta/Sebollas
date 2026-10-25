// Optional integration check: uses the public WebMSX and a local Chrome.
// Dependencies: Node.js 18+ and playwright-core (see readme.md).
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright-core');
const root = path.resolve(__dirname, '..');
const rom = fs.readFileSync(path.join(root, 'Sebollas.rom'));

(async () => {
    const browser = await chromium.launch({
        executablePath: process.env.CHROME_PATH || '/usr/bin/google-chrome',
        headless: true,
        args: ['--no-sandbox', '--disable-dev-shm-usage', '--autoplay-policy=no-user-gesture-required'],
    });
    try {
        for (const machine of ['MSX2PA', 'MSX2PE']) {
            const page = await browser.newPage({ viewport: { width: 1100, height: 900 }, ignoreHTTPSErrors: true });
            const errors = [];
            page.on('pageerror', error => errors.push(error.message));
            await page.goto(`https://webmsx.org/?M=${machine}`, { waitUntil: 'domcontentloaded', timeout: 60000 });
            await page.waitForFunction(() => window.WMSX?.room?.machine && !WMSX.room.isLoading, null, { timeout: 60000 });
            const frames = n => page.evaluate(n => {
                WMSX.room.runFramesAtTopSpeed(n);
                WMSX.room.mainVideoClock.pause();
            }, n);
            const read = address => page.evaluate(address => WMSX.room.machine.bus.read(address), address);
            const memory = (address, length) => page.evaluate(({ address, length }) =>
                Array.from({ length }, (_, i) => WMSX.room.machine.bus.read(address + i)), { address, length });
            const format = await page.evaluate(data => {
                const bytes = Uint8Array.from(atob(data), c => c.charCodeAt(0));
                // No format hint or forced mapper: reproduce dropping Sebollas.rom.
                const slot = wmsx.SlotCreator.createFromROM(new wmsx.ROM('Sebollas.rom', bytes));
                WMSX.room.machine.getCartridgeSocket().insertCartridge(slot, 0, true);
                WMSX.room.machine.powerOn();
                WMSX.room.machine.reset();
                return slot.format.name;
            }, rom.toString('base64'));
            assert.equal(format, 'ASCII8');
            await frames(1000);
            assert.equal(await read(0xC000), 0, 'title state');
            assert.equal(await read(0xFCAF), 5, 'SCREEN 5 title');
            assert.deepEqual(await memory(0x8000, 32), [...rom.subarray(0x8000, 0x8020)], 'title bank');
            await page.locator('canvas').first().click();
            await frames(5);
            await page.locator('canvas').first().screenshot({ path: path.join(root, `previews/title-webmsx-${machine}.png`) });
            await page.keyboard.down('Space');
            await frames(10);
            await page.keyboard.up('Space');
            await frames(15);
            assert.equal(await read(0xC000), 1, 'road state');
            assert.equal(await read(0xFCAF), 4, 'SCREEN 4 game');
            assert.equal(await read(0xC061), 0, 'waiting for first interaction');
            for (const address of [0x6000, 0x8000, 0xA000]) {
                assert.deepEqual(await memory(address, 32), [...rom.subarray(address - 0x4000, address - 0x4000 + 32)], 'game banks');
            }
            const row = await read(0xC017);
            await frames(30);
            assert.equal(await read(0xC017), row, 'stationary before input');
            await page.keyboard.down('ArrowLeft');
            await frames(10);
            await page.keyboard.up('ArrowLeft');
            await frames(15);
            assert.equal(await read(0xC061), 1, 'driving after input');
            assert.ok(await read(0xC017) < row, 'road scrolls');
            await page.keyboard.down('Space');
            await frames(2);
            assert.equal(await read(0xC059), 1, 'horn responds');
            await page.keyboard.up('Space');
            await page.locator('canvas').first().screenshot({ path: path.join(root, `previews/game-webmsx-${machine}.png`) });
            // Jump to the natural end of the bus scene; exercise the complete
            // slideshow and credit transition without replaying the campaign.
            await page.evaluate(() => {
                const bus = WMSX.room.machine.bus;
                bus.write(0xC000, 5); bus.write(0xC06E, 2);
                bus.write(0xC063, 1); bus.write(0xC064, 0);
            });
            const waitState = async (state, loaded = false) => {
                for (let i = 0; i < 500; i++) {
                    if (await read(0xC000) === state && (!loaded ||
                        (await read(0xC063) >= 240 && await read(0xC063) < 250))) return;
                    await frames(1);
                }
                throw new Error(`Timed out waiting for state ${state}`);
            };
            await waitState(8, true);
            assert.equal(await read(0xFCAF), 8, 'SCREEN 8 illustration 1');
            await page.locator('canvas').first().screenshot({ path: path.join(root, `previews/ending-1-webmsx-${machine}.png`) });
            await frames(180);
            assert.equal(await read(0xC000), 8, 'first image stays visible');
            await waitState(9, true);
            assert.equal(await read(0xFCAF), 8, 'SCREEN 8 illustration 2');
            await page.locator('canvas').first().screenshot({ path: path.join(root, `previews/ending-2-webmsx-${machine}.png`) });
            await frames(180);
            assert.equal(await read(0xC000), 9, 'second image stays visible');
            await waitState(6);
            assert.equal(await read(0xFCAF), 4, 'credits restore SCREEN 4');
            await frames(30);
            await page.locator('canvas').first().screenshot({ path: path.join(root, `previews/credits-revealing-webmsx-${machine}.png`) });
            await frames(500);
            await page.locator('canvas').first().screenshot({ path: path.join(root, `previews/credits-webmsx-${machine}.png`) });
            await page.keyboard.down('Space');
            await frames(15);
            await page.keyboard.up('Space');
            await frames(30);
            assert.equal(await read(0xC000), 0, 'return to title');
            assert.equal(await read(0xFCAF), 5, 'title banks restored');
            assert.deepEqual(errors, [], 'browser errors');
            console.log(`PASS WebMSX ${machine}: automatic ASCII8, title, game banks, first input, scrolling, horn, ending images, credits, return to title`);
            await page.close();
        }
    } finally {
        await browser.close();
    }
})().catch(error => { console.error(error); process.exitCode = 1; });
